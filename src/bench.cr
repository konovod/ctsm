require "benchmark"
require "./ctsm"

class BenchMachine < CTSM::Machine
  property value = 0
  initial_state(First)
  transition(simple, First, to: Result1)
  transition(reset, to: First)
  transition(with_block, First, to: Result2) do
    @value += 1
    puts "1" if @value < -2
  end
  transition_if(conditional_true, First, to: Result3) do
    @value >= 0
  end
  transition_if(conditional_false, First, to: Result4) do
    @value >= 0
  end
  transition(multiple, First, Result1, to: Result5)

  before(Result6) do
    @value += 1
  end
  after(Result6) do
    @value += 1
  end
  transition(with_triggers, First, to: Result6)

  bench_transition(1000, simple_bench, First, to: ResultB)
end

BENCH_WARMUP = 1
BENCH_TIME   = 1

Benchmark.ips(warmup: BENCH_WARMUP, calculation: BENCH_TIME) do |bm|
  m = BenchMachine.new
  bm.report("reset") do
    m.reset
  end
  bm.report("simple") do
    m.simple
    m.reset
  end
  bm.report("with_block") do
    m.with_block
    m.reset
  end
  bm.report("conditional_true") do
    m.conditional_true
    m.reset
  end
  bm.report("conditional_false") do
    m.conditional_false
    m.reset
  end
  bm.report("multiple") do
    m.multiple
    m.reset
  end
  bm.report("with_triggers") do
    m.with_triggers
    m.reset
  end
end
