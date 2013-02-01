module HTTPAuth
  # Raised when the library finds data that doesn't conform to the standard
  class UnwellformedHeader < ArgumentError; end
  # Raised when the library finds data that is not strictly forbidden but doesn't know how to handle.
  class UnsupportedError < ArgumentError; end
  # Raise when validation on the request failed, most of the times this means that someone is trying to do replay attacks.
  class ValidationError < ArgumentError; end
end