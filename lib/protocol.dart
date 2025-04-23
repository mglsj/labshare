const port = 4040;
const requestGetCode = 69;

const chunkSize = 256 * 1024; // 256 Kilo Bytes

enum ResponseCode { ok, notFound, error, invalid }
