module ProductionBreakpoints
  class NotMyClass
  end

  class MyLocalsClass
    def some_method
      a = 1
      sleep 0.5
      b = a + 1
    end

    # Helpful for debugging, but delete this
    def sleep_loop
      (1..30).each { |_| some_method }
    end
  end
end
