module ProductionBreakpoints
  class NotMyClass
  end

  class MyInspectClass
    def some_method
      a = 1
      sleep 0.5
      b = a + 1
    end

    # Helpful for debugging, but delete this
    def sleep_loop(n)
      (1..n).each { |_| some_method }
    end
  end
end
