describe 'Form::Submission', type: :system do

  it '.write' do
    page_exec do
      $submission = Form::Submission.new
      $submission.write(['record', 'nesteds', 1, 'attr'], 'toto')
    end
    expect(
      page_eval do
        $submission.read(['record', 'nesteds', 1, 'attr']).to_s
      end
    ).to eq 'toto'
  end

  it '.delete' do
    page_exec do
      $submission = Form::Submission.new
      $submission.write(['record', 'nesteds', 1, 'attr'], 'toto')
    end
    expect{
      page_exec do
        $submission.delete(['record', 'nesteds', 1, 'attr'])
      end
    }.to change{
      page_eval do
        $submission.read(['record', 'nesteds', 1, 'attr']).nil?
      end
    }.from(false).to(true)
  end

  describe 'associations' do
    before(:each) do
      page_exec do
        $submission = Form::Submission.new
      end
    end

    it '.write_association' do
      expect{
        page_exec do
          $submission.write_association(['record', 'nesteds'], [{attr: 'A'}, {attr: 'B'}])
          $submission.write_association_values(['record', 'nesteds'], [{attr: 'A'}, {attr: 'B'}]) # because write_association don't write values anymore
        end
      }.to change {
        page_eval do
          $submission.read_association(['record', 'nesteds']).to_n
        end
      }.to(eq([{'attr' => 'A'}, {'attr' => 'B'}])).and change {
        page_eval do
          $submission.read(['record', 'nesteds']).to_n # same as read_association
        end
      }.to(eq([{'attr' => 'A'}, {'attr' => 'B'}])).and change {
        page_eval do
          $submission.read(['record', 'nesteds', 1, 'attr']).to_s
        end
      }.to eq 'B'
    end

    it '.write' do
      page_exec do
        $submission = Form::Submission.new
        $submission.write_association(['record', 'nesteds'], [{attr: 'A'}, {attr: 'B'}])
      end
      expect{
        page_exec do
          $submission.write(['record', 'nesteds', 1, 'attr'], 'C')
        end
      }.to change {
        page_eval do
          $submission.read_association(['record', 'nesteds']).to_n
        end
      }.to eq [{'attr' => 'A'}, {'attr' => 'C'}]
    end

    it '.delete' do
      page_exec do
        $submission = Form::Submission.new
        $submission.write_association(['record', 'nesteds'], [{attr: 'A'}, {attr: 'B'}])
        $submission.write_association_values(['record', 'nesteds'], [{attr: 'A'}, {attr: 'B'}]) # because write_association don't write values anymore
      end

      expect{
        page_exec do
          $submission.delete(['record', 'nesteds', 1, 'attr'])
        end
      }.to change{
        page_eval do
          $submission.read_association(['record', 'nesteds']).map{|n| n[:attr].inspect}.to_n
        end
      }.to ['"A"', 'nil']
    end

    it '.destroy' do
      page_exec do
        $submission = Form::Submission.new
        $submission.write_association(['record', 'nesteds'], [{attr: 'A'}, {attr: 'B'}])
      end

      expect{
        page_exec do
          $submission.destroy(['record', 'nesteds', 1])
        end
      }.to change {
        page_eval do
          $submission.read(['record', 'nesteds', 1, '_destroy']).present?
        end
      }.to(true).and not_change{
        page_eval do
          $submission.read_association(['record', 'nesteds']).map{|n| n[:attr].inspect}.to_n
        end
      }
    end

  end


  describe 'DynamicFormSubmission' do

    it '.params' do
      page_exec do
        $submission = Form::DynamicFormSubmission.new
        $submission.write(['record', 'nesteds', 1, 'attr'], 'toto')
      end
      expect(
        page_eval do
          $submission.params.to_n
        end
      ).to eq(
        {
          'record@0.nesteds@1' => {
            'attr' => 'toto'
          }
        }
      )
    end

    it 'initial params' do
      expect(
        page_eval do
          Form::DynamicFormSubmission.new({'record@0.nesteds@1' => {'attr' => 'toto'}}).params.to_n
        end
      ).to eq(
        { 'record@0.nesteds@1' => { 'attr' => 'toto' } }
      )
    end

  end

  describe 'RecordSubmission' do
    it '.params' do
      page_exec do
        $submission = Form::RecordSubmission.new
        $submission.write(['record', 'nesteds', 1, 'attr'], 'toto')
      end
      expect(
        page_eval do
          $submission.params.to_n
        end
      ).to eq(
        {
          'record' => {
            'nesteds_attributes' => [
              {
              },
              {
                'attr' => 'toto'
              }
            ]
          }
        }
      )
    end

    it 'initial params' do
      expect(
        page_eval do
          Form::RecordSubmission.new({'record' => { 'nesteds_attributes' => [{}, {'attr' => 'toto'}]}}).params.to_n
        end
      ).to eq(
        {'record' => { 'nesteds_attributes' => [{}, {'attr' => 'toto'}]}}
      )
    end

  end

end
