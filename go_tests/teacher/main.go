package main

import (
	"context"
	"fmt"
	"net"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/grandcat/zeroconf"
)

const (
	serviceName = "_libshare"
	serviceType = "_p2p._tcp"
	domain      = "local."
	port        = 8080
)

type Peer struct {
	ID      string
	Address string
	Port    int
	Info    map[string]string
}

func main() {
	// Create a context that can be canceled
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Start our TCP server for peer communication
	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		fmt.Printf("Failed to start TCP server: %v\n", err)
		return
	}
	defer listener.Close()

	// Generate a unique instance name
	hostname, _ := os.Hostname()
	instanceName := fmt.Sprintf("%s-%d", hostname, os.Getpid())

	// Register our service
	service, err := zeroconf.Register(
		instanceName,                      // Instance name
		serviceType,                       // Service type
		domain,                            // Domain
		port,                              // Port
		[]string{"txtv=1", "app=example"}, // TXT records
		nil,                               // Interfaces to advertise on (nil = all)
	)
	if err != nil {
		fmt.Printf("Failed to register zeroconf service: %v\n", err)
		return
	}
	defer service.Shutdown()

	fmt.Printf("Published service: %s.%s%s on port %d\n", instanceName, serviceType, domain, port)

	// Keep track of discovered peers
	peersMutex := sync.RWMutex{}
	peers := make(map[string]Peer)

	// Start discovering peers
	go discoverPeers(ctx, &peersMutex, peers)

	// Connect to discovered peers periodically
	go func() {
		for {
			time.Sleep(10 * time.Second)
			connectToPeers(&peersMutex, peers)
		}
	}()

	// Wait for interrupt signal
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig

	fmt.Println("Shutting down...")
}

func discoverPeers(ctx context.Context, peersMutex *sync.RWMutex, peers map[string]Peer) {
	resolver, err := zeroconf.NewResolver(nil)
	if err != nil {
		fmt.Printf("Failed to create resolver: %v\n", err)
		return
	}

	// Channel to receive discovered services
	entries := make(chan *zeroconf.ServiceEntry)

	// Start browsing
	err = resolver.Browse(ctx, serviceType, domain, entries)
	if err != nil {
		fmt.Printf("Failed to browse: %v\n", err)
		return
	}

	// Process discovered services
	go func() {
		for entry := range entries {
			if len(entry.AddrIPv4) == 0 && len(entry.AddrIPv6) == 0 {
				continue
			}

			// Choose the first IP (IPv4 preferred)
			var ip string
			if len(entry.AddrIPv4) > 0 {
				ip = entry.AddrIPv4[0].String()
			} else {
				ip = entry.AddrIPv6[0].String()
			}

			// Create a new peer
			peer := Peer{
				ID:      entry.Instance,
				Address: ip,
				Port:    entry.Port,
				Info:    make(map[string]string),
			}

			// Parse TXT records
			for _, txt := range entry.Text {
				if len(txt) > 0 {
					parts := strings.SplitN(txt, "=", 2)
					if len(parts) == 2 {
						peer.Info[parts[0]] = parts[1]
					}
				}
			}

			// Store the peer
			peersMutex.Lock()
			peers[peer.ID] = peer
			peersMutex.Unlock()

			fmt.Printf("Discovered peer: %s at %s:%d\n", peer.ID, peer.Address, peer.Port)
		}
	}()
}

func connectToPeers(peersMutex *sync.RWMutex, peers map[string]Peer) {
	hostname, _ := os.Hostname()
	myID := fmt.Sprintf("%s-%d", hostname, os.Getpid())

	peersMutex.RLock()
	defer peersMutex.RUnlock()

	for id, peer := range peers {
		// Skip connecting to ourselves
		if id == myID {
			continue
		}

		// Connect to the peer
		go func(p Peer) {
			fmt.Printf("Connecting to peer %s at %s:%d\n", p.ID, p.Address, p.Port)
			conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", p.Address, p.Port), 5*time.Second)
			if err != nil {
				fmt.Printf("Failed to connect to peer %s: %v\n", p.ID, err)
				{
					defer conn.Close()

					// Read incoming message
					buffer := make([]byte, 1024)
					conn.SetReadDeadline(time.Now().Add(5 * time.Second))
					n, err := conn.Read(buffer)
					if err != nil {
						fmt.Printf("Error reading from connection: %v\n", err)
						return
					}

					message := string(buffer[:n])
					fmt.Printf("Received message: %s\n", message)

					// Send response
					hostname, _ := os.Hostname()
					response := fmt.Sprintf("Hello from %s! I got your message: %s", hostname, message)
					_, err = conn.Write([]byte(response))
					if err != nil {
						fmt.Printf("Error sending response: %v\n", err)
						return
					}
				}
			}
			defer conn.Close()

			// Send a message
			message := fmt.Sprintf("Hello from %s!", myID)
			_, err = conn.Write([]byte(message))
			if err != nil {
				fmt.Printf("Error sending message to %s: %v\n", p.ID, err)
				return
			}

			// Read response
			buffer := make([]byte, 1024)
			conn.SetReadDeadline(time.Now().Add(5 * time.Second))
			n, err := conn.Read(buffer)
			if err != nil {
				fmt.Printf("Error reading from %s: %v\n", p.ID, err)
				return
			}

			fmt.Printf("Received from %s: %s\n", p.ID, string(buffer[:n]))
		}(peer)
	}
}
