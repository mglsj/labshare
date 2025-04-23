const port = 4040;
const requestGetCode = 69;

const chunkSize = 64 * 1024; // 64 Kilo Bytes

enum ResponseCode { ok, notFound, error, invalid }
