# frozen_string_literal: true

class ConvertHashWithIndifferentAccessInDynamicFormSubmissions < ActiveRecord::Migration[8.0]
  def up
    Dynamic::Form::Submission.select(:id).find_each do |s|
      params, original_params = ActiveRecord::Base.connection.select_values("SELECT params, original_params FROM dynamic_form_submissions WHERE id = '#{s.id}'")

      params_ = params.present? ? YAML.load(params).to_hash.to_yaml : nil
      original_params_ = original_params.present? ? YAML.load(original_params).to_hash.to_yaml : nil

      query = %Q[UPDATE dynamic_form_submissions SET params = $1, original_params = $2 WHERE dynamic_form_submissions.id = $3]
      ActiveRecord::Base.connection.exec_query(query, 'SQL', [params_, original_params_, s.id], prepare: true)
    end
  end

  def down
  end
end
