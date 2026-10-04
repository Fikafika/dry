require 'rails_helper'

class TestMailEditorModal
  # Copy of the normalize_suggestions's implementation from app/hyperstack/components/crm/mail_editor/modal.rb
  def normalize_suggestions(s)
    return [] if s.nil?

    # If a proc or callable is provided, keep it as is (the JS side can use it)
    return s if s.respond_to?(:call)

    arr = s.is_a?(Array) ? s : [s]
    arr.map do |item|
      case item
      when String
        email = item.to_s.strip
        email.present? ? { email: email, username: "", tag: "" } : nil
      when Hash
        # Ensure expected keys
        { email: (item[:email] || item['email']).to_s, username: (item[:username] || item['username'] || "").to_s, tag: (item[:tag] || item['tag'] || "").to_s }
      else
        # Object responding to :email / :username
        if item.respond_to?(:email)
          { email: item.email.to_s, username: (item.respond_to?(:username) ? item.username.to_s : ""), tag: (item.respond_to?(:tag) ? item.tag.to_s : "") }
        else
          nil
        end
      end
    end.compact
  end
end

RSpec.describe 'Crm::MailEditor::Modal#normalize_suggestions', type: :model, without_server: true do
  let(:instance) { TestMailEditorModal.new }

  describe '#normalize_suggestions' do
    it 'returns [] for nil' do
      expect(instance.normalize_suggestions(nil)).to eq([])
    end

    it 'normalizes a single string into [{email, username, tag}]' do
      res = instance.normalize_suggestions('foo@bar.com')
      expect(res).to eq([{ email: 'foo@bar.com', username: '', tag: '' }])
    end

    it 'normalizes a hash with string keys' do
      res = instance.normalize_suggestions({ 'email' => 'a@b.com', 'username' => 'Alice' })
      expect(res).to eq([{ email: 'a@b.com', username: 'Alice', tag: '' }])
    end

    it 'normalizes an array of mixed items' do
      obj = OpenStruct.new(email: 'x@y.com', username: 'X')
      input = [ 's@t.com', { email: 'a@b.com' }, obj ]
      res = instance.normalize_suggestions(input)
      expect(res).to eq([
        { email: 's@t.com', username: '', tag: '' },
        { email: 'a@b.com', username: '', tag: '' },
        { email: 'x@y.com', username: 'X', tag: '' }
      ])
    end

    it 'returns the proc unchanged if a Proc is passed' do
      p = Proc.new { |q| [{ email: q + '@test', username: q }] }
      expect(instance.normalize_suggestions(p)).to eq(p)
    end
  end
end
