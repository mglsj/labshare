const port = 4040;
const requestGetCode = 69;

const chunkSize = 1024; // 1000 Bytes

enum ResponseCode { ok, notFound, error, invalid }
