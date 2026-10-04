module EnvTitle

  def env_title
    return unless ENV['ENV_TITLE'] && !ENV['ENV_TITLE'].start_with?('prod')
    H4(class: "mx-2") do
      SPAN(class: "badge badge-danger") do
        ENV['ENV_TITLE']
      end
    end
  end

end
