if Hyperstack.env == 'test'
  include WebMock::API
end

class Test < HyperComponent

  render do
    @@instance = self
    if @test_block
      instance_exec(&@test_block)
    end
  end

  def self.instance
    @@instance
  end

  def mount(&block)
    return unless block_given?
    @test_block = block
    mutate
  end

end


