module ApplicationHelper

  def default_title
    [current_community&.name, I18n.t('shared.application_name')].compact.join(' - ')
  end

  def current_theme_path
    result = nil
    case request.path.to_s
    when /^\/crm\/[^\/]+\/forms\/[^\/]+/
      result ||= current_form_theme_path
      result ||= current_community_theme_path
    when /^\/crm\//
      result ||= current_community_theme_path
    end
    result ||= 'application'
    return result
  end

  def env_tag(env_name)
    meta_name = env_name.underscore.gsub('_', '-')
    %Q[<meta name="#{meta_name}" content="#{ENV[env_name]}">].html_safe
  end

  private

  def current_community
    c_name = community_name
    return unless c_name
    return ::Community.find_by_permalink([c_name, c_name.gsub(/([^0-9])(\d)/, '\1-\2')])
  end

  def current_community_theme_path
    result = nil
    c = current_community
    if c
      theme_id = c&.theme_id
      result = theme_path(crm_schema_name, theme_id)
    end
    return result
  end

  def crm_schema_name
    request.path.split('/')[2]&.gsub('-', '_')
  end

  def community_name
    request.path.split('/')[2]&.gsub('_', '-')
  end

  def current_form_theme_path
    schema_name = crm_schema_name
    form_id = request.path.split('/')[4]
    if schema_name
      form = nil
      form = ::Dynamic::Form.includes(theme: 1).where(schema_id: schema_name).find_without_cache(form_id)
      begin
        form.__promise__.await(20)
      rescue Timeout::Error => e
        Rails.logger.info "fail to find Dynamic::Form-#{form_id} in 20 seconds"
      end
      if form.loaded?
        result = theme_path(schema_name, form.theme)
      end
    end
    return result
  end

  def theme_path(schema_name, theme, compile_if_missing = true)
    return unless schema_name && theme

    if theme.is_a?(::Dynamic::Theme)
      theme_id = theme.id
      timestamp = theme.updated_at.to_s.gsub(/\.|-|:|Z|T/, '')
    else
      theme_id = theme
    end

    if theme_id
      theme_dir = "public/themes/#{schema_name}"
      path = nil
      if timestamp
        s = "#{theme_id}-#{timestamp}.css"
        if File.exist?("#{theme_dir}/#{s}")
          path = "#{ENV['APP_PATH_PREFIX']}/themes/#{schema_name}/#{s}"
        end
      else
        # use last generated theme
        s = Dir.entries(theme_dir).select{|e| e =~ /^#{theme_id}\-\d+\.css$/ }.sort.last rescue nil
        path = "#{ENV['APP_PATH_PREFIX']}/themes/#{schema_name}/#{s}" if s
      end

      if path
        return path
      elsif compile_if_missing
        Rails.logger.info "Css is missing for theme #{theme_id}. Compile it"
        includes = ::Dynamic::Theme.includes_for_compile
        t = ::Dynamic::Theme.includes(includes).find_without_cache(theme_id)
        begin
          t.__promise__.await(20)
        rescue Timeout::Error => e
          Rails.logger.info "fail to find Dynamic::Theme-#{theme_id} in 20 seconds"
        end
        if t.loaded?
          t.compile_to_file(true)
          r = theme_path(schema_name, theme, false)
          Rails.logger.info "#{r} compiled"
          return r
        else
          Rails.logger.info "fail to find Dynamic::Theme-#{theme_id}"
        end
      end
    end

    return
  end

end
