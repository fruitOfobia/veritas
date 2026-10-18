if ENV["R2_ACCESS_KEY_ID"].present?
  require "aws-sdk-s3"
  Aws.config.update(
    request_checksum_calculation: "when_required",
    response_checksum_validation: "when_required"
  )
end
