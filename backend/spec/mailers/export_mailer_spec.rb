describe ExportMailer, type: :mailer, elasticsearch: false, sidekiq: false do

  context 'attachments' do
    before(:each) do
      Rails.application.config.action_mailer.raise_delivery_errors = true
      options = {attachments: {'text.txt' => 'Pour toto'}}
      @mail = ExportMailer.result_email('test@mail.com', 'toto@mail.com', nil, 'test', '', options).deliver_now
    end

    it 'should send email' do
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'should have an attachment' do
      expect(@mail.attachments.count).to eq(1)
    end

  end

end