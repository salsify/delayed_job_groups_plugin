# frozen_string_literal: true

module TestJobs
  class Foo; end

  class FailingJob
    def perform
      raise 'Test failure'
    end
  end

  class NoOpJob
    def perform

    end
  end

  class CompletionJob
    cattr_accessor :invoked

    def perform
      CompletionJob.invoked = true
    end
  end

  class CancellationJob
    cattr_accessor :invoked

    def perform
      CancellationJob.invoked = true
    end
  end
end
