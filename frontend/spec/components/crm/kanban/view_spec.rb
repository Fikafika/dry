describe 'Crm::Kanban::View', type: :system do
  before(:each) do
    page_exec do
      $schema = Dynamic::Schema.new(
        name: 'Uneek',
        klasses: [
          {
            id: 1,
            name: 'Contact',
            route_key: 'contacts',
            translations: [
              {
                human_name: 'Contact',
                locale: 'en',
              },
              {
                human_name: 'Contact',
                locale: 'fr',
              },
            ],
            attrs: [
              {
                id: 1,
                name: 'civility',
                translations: [
                  {
                    human_name: 'Civility',
                    locale: 'en',
                  },
                  {
                    human_name: 'Civilite',
                    locale: 'fr',
                  },
                ],
                values: [{
                  id: 1,
                  name: 'mr',
                  translations: [
                    {
                      human_name: 'Mr',
                      locale: 'en',
                    },
                    {
                      human_name: 'Monsieur',
                      locale: 'fr',
                    },
                  ]
                }, {
                  id: 2,
                  name: 'mrs',
                  translations: [
                    {
                      human_name: 'Mrs',
                      locale: 'en',
                    },
                    {
                      human_name: 'Madame',
                      locale: 'fr',
                    },
                  ]
                }],
                type: 'Enum',
              }
            ],
            associations: [
              {
                id: 1,
                name: 'account',
                target_klass_id: 2,
                type: 'BelongsTo',
                translations: [
                  {
                    human_name: 'account',
                    locale: 'en',
                  },
                  {
                    human_name: 'entreprise',
                    locale: 'fr',
                  },
                ],
              },
              {
                id: 1,
                name: 'emails',
                target_klass_id: 3,
                type: 'HasMany',
                translations: [
                  {
                    human_name: 'e-mails',
                    locale: 'en',
                  },
                  {
                    human_name: 'e-mails',
                    locale: 'fr',
                  },
                ],
              },
            ],
            attachments: [
              {
                id: 1,
                name: 'photo',
                type: 'HasOne',
              }
            ],
          },
          {
            id: 2,
            name: 'Account',
            route_key: 'accounts',
            translations: [
              {
                human_name: 'Account',
                locale: 'en',
              },
              {
                human_name: 'Account',
                locale: 'fr',
              },
            ],
            attrs: [
              {
                id: 2,
                name: 'name',
                type: 'String',
              }
            ]
          },
          {
            id: 3,
            name: 'Email',
            route_key: 'emails',
            translations: [
              {
                human_name: 'E-mail',
                locale: 'en',
              },
              {
                human_name: 'E-mail',
                locale: 'fr',
              },
            ],
            attrs: [
              {
                id: 4,
                name: 'address',
                type: 'String',
              }
            ]
          },
          {
            id: 4,
            name: 'Issue',
            route_key: 'issues',
            translations: [
              {
                human_name: 'Issue',
                locale: 'en',
              },
              {
                human_name: 'Ticket',
                locale: 'fr',
              },
            ],
            attrs: [
              {
                id: 5,
                name: 'description',
                translations: [
                  {
                    human_name: 'Description',
                    locale: 'en',
                  },
                  {
                    human_name: 'Description',
                    locale: 'fr',
                  },
                ],
                type: 'String',
              },
              {
                id: 6,
                name: 'title',
                translations: [
                  {
                    human_name: 'Title',
                    locale: 'en',
                  },
                  {
                    human_name: 'Titre',
                    locale: 'fr',
                  },
                ],
                type: 'String',
              },
              {
                id: 7,
                name: 'step',
                translations: [
                  {
                    human_name: 'Step',
                    locale: 'en',
                  },
                  {
                    human_name: 'Etape',
                    locale: 'fr',
                  },
                ],
                values: [
                  {
                    id: 1,
                    name: 'to_do',
                    translations: [
                      {
                        human_name: 'To do',
                        locale: 'en',
                      },
                      {
                        human_name: 'A faire',
                        locale: 'fr',
                      },
                    ]
                  },
                  {
                    id: 2,
                    name: 'on_going',
                    translations: [
                      {
                        human_name: 'On going',
                        locale: 'en',
                      },
                      {
                        human_name: 'En cours',
                        locale: 'fr',
                      },
                    ]
                  },
                  {
                    id: 3,
                    name: 'done',
                    translations: [
                      {
                        human_name: 'Done',
                        locale: 'en',
                      },
                      {
                        human_name: 'Fini',
                        locale: 'fr',
                      },
                    ]
                  }
                ],
                type: 'Enum',
              }
            ],
            associations: [
              {
                id: 1,
                name: 'supervisor',
                target_klass_id: 1,
                type: 'BelongsTo',
                translations: [
                  {
                    human_name: 'supervisor',
                    locale: 'en',
                  },
                  {
                    human_name: 'responsable',
                    locale: 'fr',
                  },
                ],
              },
              {
                id: 2,
                name: 'sprint',
                target_klass_id: 5,
                type: 'BelongsTo',
                translations: [
                  {
                    human_name: 'sprint',
                    locale: 'en',
                  },
                  {
                    human_name: 'sprint',
                    locale: 'fr',
                  },
                ],
              },
            ],
          },
          {
            id: 5,
            name: 'Sprint',
            route_key: 'sprints',
            translations: [
              {
                human_name: 'Sprint',
                locale: 'en',
              },
              {
                human_name: 'Sprint',
                locale: 'fr',
              },
            ],
            attrs: [
              {
                id: 1,
                name: 'current_sprint',
                type: 'Boolean',
              },
              {
                id: 2,
                name: 'name',
                type: 'String',
              },
            ],
            associations: [
              {
                id: 1,
                name: 'tickets',
                target_klass_id: 4,
                type: 'HasMany',
                translations: [
                  {
                    human_name: 'tickets',
                    locale: 'en',
                  },
                  {
                    human_name: 'tickets',
                    locale: 'fr',
                  },
                ],
              },
            ],
          },
        ]
      )
      $schema.status_code = 200 # mark as loaded
      $schema.load_constants
    end
  end

  after(:each) do
    page.driver.quit
    # quit after each test because sometime two successive tests cause Selenium::WebDriver::Error::ScriptTimeoutError :(
    # the previous big page_exec that load the schema seems to freeze chrome
  end

  context 'class doesnt have required attributes' do
    before(:each) do
      mount do
        $kanban = Crm::Kanban::View(
          relation: D::Uneek::Contact,
          column_attribute: "step",
        )
      end
    end

    it 'should not have columns' do
      expect(page).to_not have_css("div.flex-column")
    end
  end

  context 'class has the required attributes' do
    before(:each) do
      page_exec do
        $tickets = [
          {
            "id":"1",
            "title":"Test to_do",
            "description":"Test description",
            "step":"to_do",
            "supervisor_id":"1",
            "supervisor": {
              "id":"1",
              "civility":"mr",
              "first_name":"Cesaire",
              "last_name":"Bertrand",
              "name":"Cesaire Bertrand",
              "photo": {
                "name":"photo",
                "record": {
                  "id":"d0fdbb50-4173-11ec-b2c9-0242ac12000a",
                },
                "attachment": {
                  "id":"d109a2b2-4173-11ec-b2c9-0242ac12000a",
                  "name":"photo",
                  "record_type":"D::Uneek::Contact",
                  "record_id":"d0fdbb50-4173-11ec-b2c9-0242ac12000a",
                  "blob_id":"d108d06c-4173-11ec-b2c9-0242ac12000a",
                  "signed_id":"eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWxrTVRBNFpEQTJZeTAwTVRjekxURXhaV010WWpKak9TMHdNalF5WVdNeE1qQXdNR0VHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--b100b51b2cfcf0c182d6cf8122ca6fc065b85bff",
                }
              }
            }
          },
          {
            "id":"2",
            "title":"Test on_going 1",
            "description":"",
            "step":"on_going",
          },
          {
            "id":"3",
            "title":"Test on_going 2",
            "description":"",
            "step":"on_going"
          }
        ]

        stub_request(:get, "/api/d/uneek/issues.json?per=100").to_return do |request|
          {
            status: 200,
            body: $tickets.to_json,
          }
        end

        stub_request(:patch, "/api/d/uneek/issues/1.json").to_return do |request|
          $tickets[0] = {
            "id": "1",
            "title": "Test to_do",
            "description": "Test description",
            "step": "on_going"
          }

          {
            status: 200,
            body: {
              "id": "1",
              "title": "Test to_do",
              "description": "Test description",
              "step": "on_going"
            }.to_json,
          }
        end

      end

      mount do
        Crm::Kanban::View(
          relation: D::Uneek::Issue,
          column_attribute: "step",
        )
      end
    end

    it 'should have one column "?"' do
      expect(page).to have_css("[data-element_id='non-categorized-col']", count: 1)
    end

    it 'should have one column for each possible value of step' do
      expect(page).to have_css("[data-element_id='done']", count: 1)
      expect(page).to have_css("[data-element_id='on_going']", count: 1)
      expect(page).to have_css("[data-element_id='to_do']", count: 1)
    end

    it 'should have n+1 number of column' do
      expect(page).to have_css("[data-element_id]", count: 4)
    end

    it 'should place the ticket on the right column' do
      expect(page.find("[data-element_id='to_do']")).to have_css("div.card", count: 1, visible: false)
    end

    it 'should have the correct number of tickets' do
      expect(page.find("[data-element_id='on_going']")).to have_css("div.card", count: 2, visible: false)
    end

    xit 'should open edit_url on click' do #no edit_url as request is nil (see /frontend/app/hyperstack/component/crm.rb)
      expect(page).to_not have_css('div#right-panel')
      page.find("[data-element_id='to_do']").find('div.card-body').click
      expect(page).to have_css('div#right-panel')
    end

    it 'should change ticket value when dragging and dropping' do
      page.find("[data-element_id='to_do']").click # open column
      page.find("[data-element_id='on_going']").click # open column
      expect(page.find("[data-element_id='to_do']")).to have_css("div.card", count: 1)
      expect(page.find("[data-element_id='on_going']")).to have_css("div.card", count: 2)
      source = page.find("div.card[data-id='1']")
      target = page.find("[data-element_id='on_going']")
      source.drag_to target
      expect(page.find("[data-element_id='to_do']")).to have_css("div.card", count: 0)
      expect(page.find("[data-element_id='on_going']")).to have_css("div.card", count: 3)
    end

    xit 'should display supervisor name' do # TODO: Mock form that contains supervisor
      expect(page.find("[data-element_id='to_do'] .card")).to have_content('Cesaire Bertrand')
    end
  end

  context 'class is scoped' do
    before(:each) do
      page_exec do
        $tickets = [
          {
            "id":"2",
            "title":"Test on_going 1",
            "description":"",
            "step":"on_going"
          },
          {
            "id":"3",
            "title":"Test on_going 2",
            "description":"",
            "step":"on_going"
          }
        ]
        stub_request(:get, "/api/d/uneek/issues.json?where%5Bstep%5D=on_going&per=100").to_return do |request|
          {
            status: 200,
            body: $tickets.to_json,
          }
        end
      end

      mount do
        Crm::Kanban::View(
          relation: D::Uneek::Issue.where(step: "on_going"),
          column_attribute: "step",
        )
      end
    end

    it 'should place only the tickets in the scope' do
      expect(page.find("[data-element_id='to_do']")).to have_css("div.card", count: 0, visible: false)
      expect(page.find("[data-element_id='on_going']")).to have_css("div.card", count: 2, visible: false)
    end
  end

  context 'class is a sprint' do
    before(:each) do
      page_exec do
        $tickets = [
          {
            "id": "1",
            "title": "Ticket on sprint 1",
            "description": "Test description",
            "step": "to_do",
          },
          {
            "id": "2",
            "title": "Ticket on sprint 2",
            "description": "",
            "step": "on_going",
          },
          {
            "id": "3",
            "title": "Ticket not assigned to a sprint",
            "description": "",
            "step": "on_going"
          }
        ]

        $tickets_sprint_1 = [
          {
            "id":"1",
            "title":"Ticket on sprint 1",
            "description":"Test description",
            "step":"to_do"
          }
        ]

        $tickets_sprint_2 = [
          {
            "id":"2",
            "title":"Ticket on sprint 2",
            "description":"",
            "step":"on_going"
          }
        ]

        $sprints = [
          {
            "id":"1",
            "name":"Sprint 1",
            "current_sprint":true
          },
          {
            "id":"2",
            "name":"Sprint 2"
          }
        ]

        $sprints_current = [
          {
            "id":"1",
            "name":"Sprint 1",
            "current_sprint":true,
          }
        ]

        stub_request(:get, "/api/d/uneek/issues.json?per=100").to_return do |request|
          {
            status: 200,
            body: $tickets.to_json,
          }
        end

        stub_request(:get, "/api/d/uneek/sprints.json").to_return do |request|
          {
            status: 200,
            body: $sprints.to_json,
          }
        end

        stub_request(:get, "/api/d/uneek/sprints.json?where%5Bcurrent_sprint%5D=true").to_return do |request|
          {
            status: 200,
            body: $sprints_current.to_json,
          }
        end

        stub_request(:get, "/api/d/uneek/issues.json?where%5Bsprint_id%5D=1&where%5Bcurrent_sprint%5D=true&per=100").to_return do |request|
          {
            status: 200,
            body: $tickets_sprint_1.to_json,
          }
        end

        stub_request(:get, "/api/d/uneek/issues.json?where%5Bsprint_id%5D=1&per=100").to_return do |request|
          {
            status: 200,
            body: $tickets_sprint_1.to_json,
          }
        end

        stub_request(:get, "/api/d/uneek/issues.json?where%5Bsprint_id%5D=2&per=100").to_return do |request|
          {
            status: 200,
            body: $tickets_sprint_2.to_json,
          }
        end

        $sprint_current = D::Uneek::Sprint.where(current_sprint: true).last
      end
    end

    context 'class has no current sprint' do
      before(:each) do
        mount do
          Crm::Kanban::View(
            sprint_dropdown: true,
            relation: D::Uneek::Issue,
            column_attribute: "step",
            sprint_param: 'sprint',
          )
        end
      end

      it 'should show the select sprint' do
        expect(page).to have_css("select.form-select", count: 1)
      end

      it 'should have all sprints in the select sprint' do
        expect(page.find("select.form-select")).to have_css("option", count: 3)
      end

      it 'should select the default sprint' do
        expect(page.find("select.form-select").value).to eq("0")
      end

      it 'should show all tickets' do
        expect(page).to have_css("div.card", count: 3, visible: false)
      end

      it 'should show only the tickets of the chosen sprint' do
        page.find("select.form-select").find("option[value='1']").click
        expect(page).to have_css("div.card", count: 1, visible: false)
        # expect(page.find("div.card")).to have_content("Ticket on sprint 1") # TODO

        page.find("select.form-select").find("option[value='2']").click
        expect(page).to have_css("div.card", count: 1, visible: false)
        # expect(page.find("div.card")).to have_content("Ticket on sprint 2") # TODO

        page.find("select.form-select").find("option[value='0']").click
        expect(page).to have_css("div.card", count: 3, visible: false)
      end
    end

    context 'class has a current sprint' do
      before(:each) do
        mount do
          Crm::Kanban::View(
            sprint_dropdown: true,
            current_sprint: D::Uneek::Sprint.where(current_sprint: true).last,
            relation: D::Uneek::Issue,
            column_attribute: 'step',
            sprint_param: 'sprint',
          )
        end
      end

      it 'should show the select sprint' do
        expect(page).to have_css("select.form-select", count: 1)
      end

      it 'should have all sprints in the select sprint' do
        expect(page.find("select.form-select")).to have_css("option", count: 3)
      end

      it 'should select the current sprint by default' do
        expect(page.find("select.form-select").value).to eq("1")
      end

      it 'should change the current sprint when clicking on the select menu' do
        page.find("select.form-select").find("option[value='2']").click
        expect(page.find("select.form-select").value).to eq("2")
      end

      it 'should show only the tickets of the current sprint' do
        expect(page).to have_css("div.card", count: 1, visible: false)
        # expect(page.find("div.card")).to have_content("Ticket on sprint 1") # TODO
      end

      it 'should show only the tickets of the chosen sprint' do
        page.find("select.form-select").find("option[value='2']").click
        expect(page).to have_css("div.card", count: 1, visible: false)
        # expect(page.find("div.card")).to have_content("Ticket on sprint 2") # TODO

        page.find("select.form-select").find("option[value='0']").click
        expect(page).to have_css("div.card", count: 3, visible: false)

        page.find("select.form-select").find("option[value='1']").click
        expect(page).to have_css("div.card", count: 1, visible: false)
        # expect(page.find("div.card")).to have_content("Ticket on sprint 1") # TODO
      end

    end

  end

  context 'when drag column' do
    before(:each) do
      mount do
        $kanban = Crm::Kanban::View(
          relation: D::Uneek::Issue,
          column_attribute: 'step',
        )
      end
    end

    it 'should change column order' do
      elements = page.all("[data-element_id='done'], [data-element_id='on_going'], [data-element_id='to_do'], [data-element_id='non-categorized-col']" )
      expect(elements[0]["data-element_id"]).to eq "non-categorized-col"
      expect(elements[1]["data-element_id"]).to eq "to_do"
      expect(elements[2]["data-element_id"]).to eq "on_going"
      expect(elements[3]["data-element_id"]).to eq "done"
      source = page.find("[data-element_id='to_do']")
      target = page.find("[data-element_id='done']")
      source.drag_to target
      expect(elements[0]["data-element_id"]).to eq "non-categorized-col"
      expect(elements[1]["data-element_id"]).to eq "on_going"
      expect(elements[2]["data-element_id"]).to eq "done"
      expect(elements[3]["data-element_id"]).to eq "to_do"
    end
  end

  context 'when column_settings is present' do
    before(:each) do
      mount do
        column_settings = [
          {value: 'done', 'column_id': 3, 'position': 2},
          {value: 'on_going', 'column_id': 2, 'position': 1},
          {value: 'to_do', 'column_id': 1, 'position': 0},
          {value: nil, 'column_id': nil, 'position': 3},
        ]
        column_states = {'non-categorized-col' => 'CLOSED', 1 => 'OPEN', 2 => 'CLOSED', 3 => 'OPEN'}
        $kanban = Crm::Kanban::View(
          relation: D::Uneek::Issue,
          column_attribute: 'step',
          column_settings: column_settings,
          column_states: column_states,
        )
      end
    end

    it 'should show columns sorted by position' do
      elements = page.all("[data-element_id='done'], [data-element_id='on_going'], [data-element_id='to_do'], [data-element_id='non-categorized-col']" )
      expect(elements[0]["data-element_id"]).to eq "to_do"
      expect(elements[1]["data-element_id"]).to eq "on_going"
      expect(elements[2]["data-element_id"]).to eq "done"
      expect(elements[3]["data-element_id"]).to eq "non-categorized-col"
    end

    it 'should have 1 CLOSED column and 2 OPEN' do
      expect(page).to have_css('div.kanban-column-reverse', count: 2)
      expect(page).to have_css('div.kanban-column', count: 2)
    end

    context 'when toggle_column' do
      it 'should OPEN the CLOSED column clicked' do
        page.find("[data-element_id='on_going']").click
        expect(page).to have_css('div.kanban-column-reverse', count: 1)
        expect(page.find("[data-element_id='on_going']")).to have_css('div.kanban-column')
      end

      it 'should CLOSE the OPEN column clicked' do
        page.find("[data-element_id='to_do']").find('.kanban-column-header').click
        expect(page).to have_css('div.kanban-column', count: 1)
        expect(page.find("[data-element_id='to_do']")).to have_css('div.kanban-column-reverse')
      end
    end

    context 'when no column_states' do
      before(:each) do
        mount do
          column_settings = [
            {value: 'done', 'column_id': 3, 'position': 2},
            {value: 'on_going', 'column_id': 2, 'position': 1},
            {value: 'to_do', 'column_id': 1, 'position': 0},
            {value: nil, 'column_id': nil, 'position': 3},
          ]
          $kanban = Crm::Kanban::View(
            relation: D::Uneek::Issue,
            column_attribute: 'step',
            column_settings: column_settings
          )
        end
      end

      it 'should have 4 CLOSED' do
        expect(page).to have_css('div.kanban-column-reverse', count: 4)
      end
    end
  end
end
