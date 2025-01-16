const Status = enum {
    ok,
    bad,
    unknown,
};

const Stage = enum {
    validate,
    awaiting_confirmation,
    confirmed,
    err,

    fn isComplete(self: Stage) bool {
        return self == .confirmed or self == .err;
    }
};
