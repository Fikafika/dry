load 'app/hyperstack/components/crm/filters/normalization.rb'
load 'app/hyperstack/components/crm/filters/merge.rb'

describe Crm::Filters::Merge, type: :system, without_server: true  do
  include Crm::Filters::Normalization
  include Crm::Filters::Merge

  it 'should manage simple hashs' do
    expect(
      merge(
        {
          "emails.address"=>{"contains"=>"o"},
        },
        {
          "emails.tag"=>{"contains"=>"t"},
        }
      )
    ).to eq(
      {
        "emails.address"=>{"contains"=>"o"},
        "emails.tag"=>{"contains"=>"t"},
      }
    )
  end

  it 'should manage simple hashs with several keys' do
    expect(
      merge(
        {
          "emails.address"=>{"contains"=>"o"},
          "emails.tag"=>{"contains"=>"t"},
        },
        {
          "emails.tag"=>{"contains"=>"t2"},
        }
      )
    ).to eq({
      "and" => [
        {"emails.address"=>{"contains"=>"o"}},
        {"emails.tag"=>{"contains"=>"t"}}, # could be more simplified ?
        {"emails.tag"=>{"contains"=>"t2"}}
      ]
    })
  end

  it 'or with simple hash' do
    expect(
      merge(
        {
          "or" => [
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ],
        },
        {
          "emails.tag"=>{"contains"=>"t2"},
        }
      )
    ).to eq({
      "and" => [
        {
          "or" => [
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ],
        },
        {
          "emails.tag"=>{"contains"=>"t2"},
        }
      ]
    })
  end

  it 'simple hash with or' do
    expect(
      merge(
        {
          "emails.tag"=>{"contains"=>"t2"},
        },
        {
          "or" => [
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ],
        }
      )
    ).to eq({
      "and" => [
        {
          "emails.tag"=>{"contains"=>"t2"},
        },
        {
          "or" => [
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ],
        },
      ]
    })
  end

  it 'and with simple hash' do
    expect(
      merge(
        {
          "and" => [
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ],
        },
        {
          "emails.tag"=>{"contains"=>"t2"},
        }
      )
    ).to eq({
      "and" => [
        {"emails.address"=>{"contains"=>"o"}},
        {"emails.tag"=>{"contains"=>"t"}},
        {"emails.tag"=>{"contains"=>"t2"}},
      ]
    })
  end

  it 'or reorganized' do
    expect(
      merge(
        {
          "emails.tag" => {
            "or" => [
              {"contains"=>"o"},
              {"contains"=>"t"},
            ],
          }
        },
        {
          "emails.tag"=>{"contains"=>"t2"},
        }
      )
    ).to eq({
      "emails.tag" => {
        "and"=>[
          {
            "or"=>[
              {"contains"=>"o"},
              {"contains"=>"t"}
            ]
          },
          {"contains"=>"t2"}
        ]
      }
    })
  end

end
