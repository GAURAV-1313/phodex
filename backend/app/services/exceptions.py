class ServiceError(Exception):
    pass


class NotFoundError(ServiceError):
    pass


class UnauthorizedError(ServiceError):
    pass


class ForbiddenError(ServiceError):
    pass


class ConflictError(ServiceError):
    pass


class LimitExceededError(ConflictError):
    def __init__(self, message: str, code: str) -> None:
        super().__init__(message)
        self.code = code
