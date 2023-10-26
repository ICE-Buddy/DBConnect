public func logDecodingError(error: Error) {
    switch error {
    case DecodingError.dataCorrupted(let context):
        print(context)
    case DecodingError.keyNotFound(let key, let context):
        print("Key '\(key)' not found:", context.debugDescription)
        print("codingPath:", context.codingPath)
    case DecodingError.valueNotFound(let value, let context):
        print("Value '\(value)' not found:", context.debugDescription)
        print("codingPath:", context.codingPath)
    case DecodingError.typeMismatch(let type, let context):
        print("Type '\(type)' mismatch:", context.debugDescription)
        print("codingPath:", context.codingPath)
    default:
        print(error.localizedDescription)
    }
}
