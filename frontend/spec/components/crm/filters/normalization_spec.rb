load 'app/hyperstack/components/crm/filters/normalization.rb'

describe Crm::Filters::Normalization, type: :system, without_server: true  do
  include Crm::Filters::Normalization

  describe 'simplify' do

    context 'or' do

      it 'should simplify if one or' do
        expect(
          simplify({'or' => [{"emails.address"=>{"contains"=>"o"}}]})
        ).to eq({"emails.address"=>{"contains"=>"o"}})
      end

      it 'should reorganize if same attribute' do
        expect(
          simplify({'or' => [{"and"=>[{"emails.address"=>{"contains"=>"o"}}]}, {"and"=>[{"emails.address"=>{"contains"=>"a"}}]}]})
        ).to eq({"emails.address"=>{"or"=>[{"contains"=>"o"}, {"contains"=>"a"}]}})
      end

      it 'should not reorganize if not same attribute' do
        expect(
          simplify({'or' => [{"and"=>[{"emails.address"=>{"contains"=>"o"}}]}, {"and"=>[{"emails.tag"=>{"contains"=>"a"}}]}]})
        ).to eq({"or"=>[{"emails.address"=>{"contains"=>"o"}}, {"emails.tag"=>{"contains"=>"a"}}]})
      end

      it 'should simplify and + or' do
        expect(
          simplify(
            {"or"=>[
              {"and"=>[
                {"civility"=>{"equal"=>"Mr."}},
                {"civility"=>{"equal"=>"Mrs."}}
              ]},
              {"and"=>[
                {"civility"=>{"equal"=>"Mrs."}}
              ]}
            ]}
          )
        ).to eq(
          {"civility"=>
            {"or"=>[
              {"and"=>[
                  {"equal"=>"Mr."},
                  {"equal"=>"Mrs."}
              ]},
              {"equal"=>"Mrs."}
            ]}
          }
        )
      end

    end

    context 'and' do

      it 'should simplify if one and' do
        expect(
          simplify({'and' => [{"emails.address"=>{"contains"=>"o"}}]})
        ).to eq({"emails.address"=>{"contains"=>"o"}})
      end

      it 'should reorganize if same attribute' do
        expect(
          simplify({'and' => [{"emails.address"=>{"contains"=>"o"}}, {"emails.address"=>{"contains"=>"a"}}]})
        ).to eq({"emails.address"=>{"and"=>[{"contains"=>"o"}, {"contains"=>"a"}]}})
      end

      it 'should not reorganize if different attribute' do
        expect(
          simplify({'and' => [{"emails.address"=>{"contains"=>"o"}}, {"emails.tag"=>{"contains"=>"a"}}]})
        ).to eq({"emails.address"=>{"contains"=>"o"}, "emails.tag"=>{"contains"=>"a"}})
      end

      it 'should apply recursivly' do
        expect(
          simplify({'and' => [{"or" => [{"emails.address"=>{"contains"=>"o"}}]}]})
        ).to eq({"emails.address"=>{"contains"=>"o"}})
      end

      it 'should simplify and+or' do
        expect(
          simplify(
            {"and" => [
              {"or" => [
                {"and" => [{"emails.address"=>{"contains"=>"o"}}]},
                {"and" => [{"emails.address"=>{"contains"=>"t"}}]},
              ]},
              {"and" => [
                {"and" => [
                  {"emails.tag"=>{"contains"=>"o"}},
                  {"emails.tag"=>{"contains"=>"t"}},
                ]},
              ]},
            ]}
          )
        ).to eq(
          {
            "emails.address"=>{"or" => [{"contains"=>"o"}, {"contains"=>"t"}]},
            "emails.tag"=>{"and" => [{"contains"=>"o"}, {"contains"=>"t"}]},
          }
        )
      end
    end

    it 'a or (b and c)' do
      expect(
        simplify(
          {"or"=>[
            {"and"=>[
              {"emails.address"=>{"contains"=>"a"}}
            ]},
            {"and"=>[
              {"emails.tag"=>{"contains"=>"b"}},
              {"emails.owner"=>{"contains"=>"c"}}
            ]}
          ]}
        )
      ).to eq(
        {"or"=>[
          {"emails.address"=>{"contains"=>"a"}},
          {
            "emails.tag"=>{"contains"=>"b"},
            "emails.owner"=>{"contains"=>"c"},
          }
        ]}
      )
    end

    it 'should simplify empty' do
      expect(
        simplify({'and' => []})
      ).to eq nil
      expect(
        simplify({'or' => []})
      ).to eq nil
      expect(
        simplify({'and' => [{'and' => []}]})
      ).to eq nil
      expect(
        simplify({'and' => [{'and' => [{'and' => [{'and' => []}]}]}]})
      ).to eq nil
    end

    it 'should not simplify when not possible' do
      filters = {"and"=>[{"or"=>[{"name"=>{"contains"=>"e"}}, {"civility"=>{"equal"=>"Mr."}}]}, {"id"=>{"contains"=>"e"}}]}
      expect(simplify(filters)).to eq(filters)
    end
  end

  describe 'dereorganize' do

    it 'hash without operator with one key should not change' do
      expect(
        dereorganize(
          {"emails.address"=>{"contains"=>"o"}}
        )
      ).to eq({"emails.address"=>{"contains"=>"o"}})
    end

    it 'hash without operator with several keys should be added in an and' do
      expect(
        dereorganize(
          {"emails.address"=>{"contains"=>"o"}, "emails.tag"=>{"contains"=>"t"}}
        )
      ).to eq(
        {"and"=>[
          {"emails.address"=>{"contains"=>"o"}},
          {"emails.tag"=>{"contains"=>"t"}},
        ]}
      )
    end

    it 'hash with an and' do
      expect(
        dereorganize(
          {"emails.address"=>{"and" => [{"contains"=>"o"}, {"contains"=>"t"}]}}
        )
      ).to eq({"and"=>[{"emails.address"=>{"contains"=>"o"}}, {"emails.address"=>{"contains"=>"t"}}]})
    end

    it 'hash with an or' do
      expect(
        dereorganize(
          {"emails.address"=>{"or" => [{"contains"=>"o"}, {"contains"=>"t"}]}}
        )
      ).to eq({"or" => [{"emails.address"=>{"contains"=>"o"}}, {"emails.address"=>{"contains"=>"t"}}]})
    end

    it 'hash with an and + or + and' do
      expect(
        dereorganize(
          {
            "emails.address"=>{"or" => [{"contains"=>"o"}, {"contains"=>"t"}]},
            "emails.tag"=>{"and" => [{"contains"=>"o"}, {"contains"=>"t"}]},
          }
        )
      ).to eq(
        {"and" => [
          {"or" => [
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.address"=>{"contains"=>"t"}},
          ]},
          {"and" => [
            {"emails.tag"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ]},
        ]}
      )
    end

    it 'hash with an and + and + or' do
      expect(
        dereorganize(
          {
            "emails.tag"=>{"and" => [{"contains"=>"o"}, {"contains"=>"t"}]},
            "emails.address"=>{"or" => [{"contains"=>"o"}, {"contains"=>"t"}]},
          }
        )
      ).to eq(
        {"and" => [
          {"and" => [
            {"emails.tag"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ]},
          {"or" => [
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.address"=>{"contains"=>"t"}},
          ]},
        ]}
      )
    end

    it 'hash with an and + and + or + and' do
      expect(
        dereorganize(
          {
            "emails.tag"=>{"and" => [{"contains"=>"o"}, {"contains"=>"t"}]},
            "emails.address"=>{"or" => [{"contains"=>"o"}, {"contains"=>"t"}]},
            "emails.name"=>{"and" => [{"contains"=>"e"}, {"contains"=>"t"}]},
          }
        )
      ).to eq(
        {"and" => [
          {"and" => [
            {"emails.tag"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ]},
          {"or" => [
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.address"=>{"contains"=>"t"}},
          ]},
          {"and" => [
            {"emails.name"=>{"contains"=>"e"}},
            {"emails.name"=>{"contains"=>"t"}},
          ]},
        ]}
      )
    end

  end

  describe 'normalize' do

    it 'should manage trivial case' do
      expect(
        normalize(
          {"emails.address"=>{"contains"=>"o"}}
        )
      ).to eq({"emails.address"=>{"contains"=>"o"}})
    end

    context 'and' do

      it 'should manage simple hash with several keys' do
        expect(
          normalize(
            {
              "emails.address"=>{"contains"=>"o"},
              "emails.tag"=>{"contains"=>"t"},
            }
          )
        ).to eq(
          {"and"=>[
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ]}
        )
      end

      it 'should manage an hash with one level with and' do
        expect(
          normalize(
            {"emails.address"=>{"and" => [{"contains"=>"o"}, {"contains"=>"a"}]}}
          )
        ).to eq({"and"=>[{"emails.address"=>{"contains"=>"o"}}, {"emails.address"=>{"contains"=>"a"}}]})
      end

    end

    it 'should manage an hash with one level with or' do
      expect(
        normalize(
          {"emails.address"=>{"or" => [{"contains"=>"o"}, {"contains"=>"a"}]}}
        )
      ).to eq({"or"=>[{"emails.address"=>{"contains"=>"o"}}, {"emails.address"=>{"contains"=>"a"}}]})
    end

    it 'should add and logical operator when when one filter' do
      expect(
        normalize(
          {"civility"=>{
            "or"=>[
              {"and"=>[
                {"equal"=>"Mr."},
                {"equal"=>"Mrs."}
              ]},
              {"equal"=>"Mrs."} # <-
            ]
          }}
        )
      ).to eq(
        {"or"=>[
          {"and"=>[
            {"civility"=>{"equal"=>"Mr."}},
            {"civility"=>{"equal"=>"Mrs."}}
          ]},
          {"and"=>[
            {"civility"=>{"equal"=>"Mrs."}}
          ]}
        ]}
      )
    end

    it 'should normalize without attribute name' do
      expect(
        normalize(
          {"or"=>[{"and"=>[{"equal"=>"Mr."}, {"equal"=>"Mrs."}]}, {"equal"=>"Mr."}]}
        )
      ).to eq(
        {"or"=>[
          {"and"=>[
            {"equal"=>"Mr."},
            {"equal"=>"Mrs."},
          ]},
          {"and"=>[
            {"equal"=>"Mr."},
          ]}
        ]}
      )
    end

  end

  describe 'normalized_to_array' do # use in frontend in order to build an UI

    it 'and' do
      expect(
        normalized_to_array(
          {"and"=>[
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ]}
        )
      ).to eq(
        [
          [
            'and', 'emails.address', [
              ['and', 'contains', 'o'],
            ]
          ],
          [
            'and', 'emails.tag', [
              ['and', 'contains', 't'],
            ]
          ]
        ]
      )
    end

    it 'or' do
      expect(
        normalized_to_array(
          {"or"=>[
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.tag"=>{"contains"=>"t"}},
          ]}
        )
      ).to eq(
        [
          [
            'and', 'emails.address', [
              ['and', 'contains', 'o'],
            ]
          ],
          [
            'or', 'emails.tag', [
              ['and', 'contains', 't'],
            ]
          ]
        ]
      )
    end

    it 'and + or' do
      expect(
        normalized_to_array(
          {"and" => [
            {"and" => [
              {"emails.tag"=>{"contains"=>"o"}},
              {"emails.tag"=>{"contains"=>"t"}},
            ]},
            {"or" => [
              {"emails.address"=>{"contains"=>"o"}},
              {"emails.address"=>{"contains"=>"t"}},
            ]},
          ]}
        )
      ).to eq(
        [
          [
            'and', 'emails.tag', [
              ['and', 'contains', 'o'],
              ['and', 'contains','t'],
            ]
          ],
          [
            'and', 'emails.address', [
              ['and', 'contains', 'o'],
              ['or', 'contains', 't'],
            ]
          ]
        ]
      )
    end

    it 'nested or' do
      expect(
        normalized_to_array(
          {"or"=>[
            {"emails.address"=>{"contains"=>"o"}},
            {"emails.address"=>{"contains"=>"a"}}
          ]}
        )
      ).to eq(
        [
          [
            'and', 'emails.address', [
              ['and', 'contains', 'o'],
              ['or', 'contains', 'a'],
            ]
          ]
        ]
      )
    end

    it '(a and b) or c' do
      expect(
        normalized_to_array(
          {"or"=>[
            {"and"=>[
              {"civility"=>{"equal"=>"Mr."}},
              {"civility"=>{"equal"=>"Mrs."}}
            ]},
            {"and"=>[
              {"civility"=>{"equal"=>"Mrs."}}
            ]}
          ]}
        )
      ).to eq(
        [
          [
            'and', 'civility', [
              ['and', 'equal', 'Mr.'],
              ['and', 'equal', 'Mrs.'],
              ['or', 'equal', 'Mrs.'],
            ]
          ]
        ]
      )
    end

    it '(a or b) and c' do
      expect(
        normalized_to_array(
          {
            "and" => [
              {"or" => [
                 {"last_name" => {"contains" => "a"}},
                 {"first_name" => {"contains" => "b"}},
              ]},
              {"company" => {"contains" => "c"}},
            ]
          }
        )
      ).to eq(
        [
          ["and", "last_name", [["and", "contains", "a"]]],
          ["or", "first_name", [["and", "contains", "b"]]],
          ["separator"],
          ["and", "company", [["and", "contains", "c"]]],
        ]
      )
    end

    it 'complex' do

      expect(
        normalized_to_array({"or"=>[{"and"=>[{"first_name"=>{"contains"=>"épi"}}]}, {"or"=>[{"and"=>[{"last_name"=>{"contains"=>"a"}}]}, {"and"=>[{"last_name"=>{"contains"=>"a"}}, {"last_name"=>{"contains"=>"r"}}]}]}]})
      ).to eq(
        [["and", "first_name", [["and", "contains", "épi"]]], ["or", "last_name", [["and", "contains", "a"], ["or", "contains", "a"], ["and", "contains", "r"]]]]
      )
    end

  end

  describe 'nested_array_to_hash' do # used in frontend

    it 'a and b' do
      expect(
        nested_array_to_hash(
          [
            ['and', 'contains', 'a'],
            ['and', 'contains', 'b'],
          ]
        )
      ).to eq(
        {'and' => [{"contains"=>"a"}, {"contains"=>"b"}]}
      )
    end

    it 'a or b' do
      expect(
        nested_array_to_hash(
          [
            ['and', 'contains', 'a'],
            ['or', 'contains', 'b'],
          ]
        )
      ).to eq(
        {'or' => [
          {"contains"=>"a"},
          {"contains"=>"b"},
        ]}
      )
    end

    it 'a and b and c' do
      expect(
        nested_array_to_hash(
          [
            ['and', 'contains', 'a'],
            ['and', 'contains', 'b'],
            ['and', 'contains', 'c'],
          ]
        )
      ).to eq(
        {'and' => [{"contains"=>"a"}, {"contains"=>"b"}, {"contains"=>"c"}]}
      )
    end

    it 'a or b or c' do
      expect(
        nested_array_to_hash(
          [
            ['and', 'contains', 'a'],
            ['or', 'contains', 'b'],
            ['or', 'contains', 'c'],
          ]
        )
      ).to eq(
        {'or' => [
          {"contains"=>"a"},
          {"contains"=>"b"},
          {"contains"=>"c"},
        ]}
      )
    end

    it 'a or (b and c) or (d and e)' do # "and" priority is superior to "or"
      expect(
        nested_array_to_hash(
          [
            ['and', 'contains', 'a'],
            ['or', 'contains', 'b'],
            ['and', 'contains', 'c'],
            ['or', 'contains', 'd'],
            ['and', 'contains', 'e'],
          ]
        )
      ).to eq(
        {'or' => [
          {"contains"=>"a"},
          {'and' => [
            {"contains"=>"b"},
            {"contains"=>"c"},
          ]},
          {"and" => [
            {"contains"=>"d"},
            {"contains"=>"e"},
          ]},
        ]}
      )
    end

    it '(a and b) or (c and d) or e' do
      expect(
        nested_array_to_hash(
          [
            ['and', 'contains', 'a'],
            ['and', 'contains', 'b'],
            ['or', 'contains', 'c'],
            ['and', 'contains', 'd'],
            ['or', 'contains', 'e'],
          ]
        )
      ).to eq(
        {'or' => [
          {'and' => [
            {"contains"=>"a"},
            {"contains"=>"b"},
          ]},
          {"and" => [
            {"contains"=>"c"},
            {"contains"=>"d"},
          ]},
          {"contains"=>"e"},
        ]}
      )
    end

    it '(a and b) or (c and d) or (e and f and g) or h or i' do
      expect(
        nested_array_to_hash(
          [
            ['and', 'contains', 'a'],
            ['and', 'contains', 'b'],
            ['or', 'contains', 'c'],
            ['and', 'contains', 'd'],
            ['or', 'contains', 'e'],
            ['and', 'contains', 'f'],
            ['and', 'contains', 'g'],
            ['or', 'contains', 'h'],
            ['or', 'contains', 'i'],
          ]
        )
      ).to eq(
        {'or' => [
          {'and' => [
            {"contains"=>"a"},
            {"contains"=>"b"},
          ]},
          {"and" => [
            {"contains"=>"c"},
            {"contains"=>"d"},
          ]},
          {"and" => [
            {"contains"=>"e"},
            {"contains"=>"f"},
            {"contains"=>"g"},
          ]},
          {"contains"=>"h"},
          {"contains"=>"i"},
        ]}
      )
    end

  end

  describe 'array_to_hash' do # use in frontend in order to build an UI

    it 'nested a and b' do
      expect(
        array_to_hash(
          [
            [
              'and', 'emails.address', [
                ['and', 'contains', 'a'],
                ['and', 'contains', 'b'],
              ]
            ]
          ]
        )
      ).to eq(
        {
          "emails.address"=>{'and' => [{"contains"=>"a"}, {"contains"=>"b"}]},
        }
      )
    end

    it 'nested a or b' do
      expect(
        array_to_hash(
          [
            [
              'and', 'emails.address', [
                ['and', 'contains', 'a'],
                ['or', 'contains', 'b'],
              ]
            ]
          ]
        )
      ).to eq(
        {
          "emails.address"=>{'or' => [{"contains"=>"a"}, {"contains"=>"b"}]},
        }
      )
    end

    it 'nested a or (b and c) or d' do
      expect(
        array_to_hash(
          [
            [
              'and', 'emails.address', [
                ['and', 'contains', 'a'],
                ['or', 'contains', 'b'],
                ['and', 'contains', 'c'],
                ['or', 'contains', 'd'],
                ['and', 'contains', 'e'],
              ]
            ]
          ]
        )
      ).to eq(
        {
          "emails.address"=>{
            'or' => [
              {"contains"=>"a"},
              {'and' => [
                {"contains"=>"b"},
                {"contains"=>"c"},
              ]},
              {'and' => [
                {"contains"=>"d"},
                {"contains"=>"e"},
              ]},
            ]
          }
        }
      )
    end

    it 'and' do
      expect(
        array_to_hash(
          [
            [
              'and', 'emails.address', [
                ['and', 'contains', 'o'],
              ]
            ],
            [
              'and', 'emails.tag', [
                ['and', 'contains', 't'],
              ]
            ]
          ]
        )
      ).to eq(
        {
          "emails.address"=>{"contains"=>"o"},
          "emails.tag"=>{"contains"=>"t"},
        }
      )
    end

    it 'or' do
      expect(
        array_to_hash(
          [
            [
              'and', 'emails.address', [
                ['and', 'contains', 'o'],
              ]
            ],
            [
              'or', 'emails.tag', [
                ['and', 'contains', 't'],
              ]
            ]
          ]
        )
      ).to eq(
        {"or"=>[
          {"emails.address"=>{"contains"=>"o"}},
          {"emails.tag"=>{"contains"=>"t"}},
        ]}
      )
    end

    it 'a or (b and c)' do
      expect(
        array_to_hash(
          [
            [
              'and', 'emails.address', [
                ['and', 'contains', 'a'],
              ]
            ],
            [
              'or', 'emails.tag', [
                ['and', 'contains', 'b'],
              ]
            ],
            [
              'and', 'emails.owner', [
                ['and', 'contains', 'c'],
              ]
            ],
          ]
        )
      ).to eq(
        {"or"=>[
          {"emails.address"=>{"contains"=>"a"}},
          {
            "emails.tag"=>{"contains"=>"b"},
            "emails.owner"=>{"contains"=>"c"},
          }
        ]}
      )
    end

    it '(a or b) and c' do
      expect(
        array_to_hash(
          [
            ["and", "last_name", [["and", "contains", "a"]]],
            ["or", "first_name", [["and", "contains", "b"]]],
            ["separator"],
            ["and", "company", [["and", "contains", "c"]]],
          ]
        )
      ).to eq(
        {
          "and" => [
            {"or" => [
              {"last_name" => {"contains" => "a"}},
              {"first_name" => {"contains" => "b"}},
            ]},
            {"company" => {"contains" => "c"}},
          ]
        }
      )
    end

    it 'nested and + and + or' do
      expect(
        array_to_hash(
          [
            [
              'and', 'civility', [
                ['and', 'equal', 'Mr.'],
                ['and', 'equal', 'Mrs.'],
                ['or', 'equal', 'Mrs.'],
              ]
            ]
          ]
        )
      ).to eq(
        {"civility"=>{
          'or' => [
            {'and' => [{"equal"=>"Mr."}, {"equal"=>"Mrs."}]},
            {"equal"=>"Mrs."},
          ]}
        }
      )
    end

    it 'or + and 2' do
      expect(
        array_to_hash(
          [
            [
              'and', 'civility', [
                ['and', 'equal', 'Mr.'],
                ['and', 'equal', 'Mrs.'],
                ['or', 'equal', 'Mrs.'],
                ['and', 'equal', 'Mr.'],
              ]
            ]
          ]
        )
      ).to eq(
        {"civility"=>{
          'or' => [
            {'and' => [{"equal"=>"Mr."}, {"equal"=>"Mrs."}]},
            {'and' => [{"equal"=>"Mrs."}, {"equal"=>"Mr."}]},
          ]}
        }
      )
    end

    it 'complex' do
      expect(
        array_to_hash(
          [
            [
              'and', 'emails.tag', [
                ['and', 'contains', 'a'],
                ['and', 'contains','b'],
              ]
            ],
            [
              'or', 'emails.address', [
                ['and', 'contains', 'c'],
                ['or', 'contains', 'd'],
                ['and', 'contains', 'e'],
              ]
            ],
            [
              'and', 'emails.owner', [
                ['and', 'contains', 'f'],
                ['or', 'contains','g'],
              ]
            ],
          ]
        )
      ).to eq(
        {"or" => [
          {"emails.tag"=>{"and"=>[{"contains"=>"a"}, {"contains"=>"b"}]}},
          {
            "emails.address"=>{
              "or"=>[
                {"contains"=>"c"},
                {"and"=>[
                  {"contains"=>"d"},
                  {"contains"=>"e"}]
                }
              ]
            },
            "emails.owner"=>{"or"=>[{"contains"=>"f"}, {"contains"=>"g"}]},
          },
        ]},
      )
    end

  end

  describe 'hash_to_array' do

    it 'and' do
      expect(
        hash_to_array(
          {"emails.address"=>{"contains"=>"o"}},
        )
      ).to eq(
        [
          [
            'and', 'emails.address', [
              ['and', 'contains', 'o'],
            ]
          ],
        ]
      )
    end

  end

end
