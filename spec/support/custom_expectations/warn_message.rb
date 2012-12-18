# Verify message is written to error output.
#
# @example
#   expect { warn("Bazinga!) }.to warn_message("Bazinga!")
#
RSpec::Matchers.define :warn_message do |message|
  match do |block|
    begin
      original_stderr = $stderr
      $stderr = StringIO.new
      block.call
      $stderr.string.include? message
    ensure
      $stderr = original_stderr
    end
  end

  description do
    "warn \"#{message}\""
  end

  failure_message_for_should do
    "expected to #{description}"
  end

  failure_message_for_should_not do
    "expected to not #{description}"
  end
end
