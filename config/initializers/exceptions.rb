class InvalidJsonError < RuntimeError; end
class DuplicateFilenameError < RuntimeError; end
class FileTooLargeError < RuntimeError; end
class TooManyFilesError < RuntimeError; end
class InvalidSubmissionError < RuntimeError; end

# Gemini API errors
module Gemini
  class Error < RuntimeError; end
  class RateLimitError < Error; end
  class InvalidRequestError < Error; end
  class APIError < Error; end
end
