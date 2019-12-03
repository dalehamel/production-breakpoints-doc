module ProductionBreakpoints
  class NotMyClass
  end

  # These each get their own file right now because there seems to be
  # some bleeding / leakage between tests. This is a hack to avoid that, until
  # I can determine what is leaking and not being properly cleaned up
  class MyUstackClass
    def some_method
      a = 1
      sleep 0.5
      b = a + 1
    end

    # Helpful for debugging, but delete this
    def sleep_loop(n=60)
      (1..n).each { |_| some_method }
    end
  end
end
