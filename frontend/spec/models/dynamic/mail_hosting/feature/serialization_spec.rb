require 'helpers/active_storage'

describe 'Dynamic::Record::Base::Serialization', type: :system, without_server: true do

  include ::RSpec::HyperResource::ActiveStorage

  before(:all) do
    $schema = Dynamic::Schema.new(
      name: 'Uneek',
      klasses: [
        {
          id: 1,
          name: 'Contact',
          route_key: 'contacts',
          attrs: [
            {
              id: 1,
              name: 'first_name',
              type: 'String'
            },
            {
              id: 2,
              name: 'last_name',
              type: 'String'
            }
          ],
          associations: [
            {
              id: 1,
              name: 'account',
              target_klass_id: 2,
              type: 'BelongsTo'
            },
            {
              id: 2,
              name: 'emails',
              target_klass_id: 3,
              type: 'HasMany'
            },
          ],
          attachments: [
            {
              id: 1,
              name: 'photo',
              type: 'HasOne',
            },
            {
              id: 2,
              name: "cin",
              type: 'HasOne'
            }
          ],
        },
        {
          id: 2,
          name: 'Account',
          route_key: 'accounts',
          attrs: [
            {
              id: 3,
              name: 'name',
              type: 'String',
            }
          ]
        },
        {
          id: 3,
          name: 'Email',
          route_key: 'emails',
          attrs: [
            {
              id: 4,
              name: 'address',
              type: 'String',
            },
            {
              id: 5,
              name: "recipient",
              type: 'String'
            }
          ],
          attachments: [
            {
              id: 3,
              name: 'documents',
              type: 'HasMany',
            }
          ]
        },
        {
          id: 4,
          name: 'Company',
          route_key: 'company',
          attrs: [
            {
              id: 6,
              name: 'name',
              type: 'String',
            }
          ],
          associations: [
            {
              id: 3,
              name: 'employees',
              target_klass_id: 1,
              type: 'HasMany'
            }
          ],
        }
      ]
    )
    $schema.status_code = 200 # mark as loaded
    $schema.load_constants

    @feature = Dynamic::MailHosting::Feature
  end

  describe '.includes_for_dot_keys' do

    context "simple keys" do
      let(:contact_klass) { "D::Uneek::Contact".safe_constantize }

      context "take attribute" do
        it "should be added 'only' option" do
          expect(@feature.includes_for_dot_keys(contact_klass, [
            'first_name', 'last_name'
          ])).to eq({
            only: ['first_name', 'last_name'],
            include: {}
          })
        end

        it "should not add non-existent attribute" do
          expect(@feature.includes_for_dot_keys(contact_klass, [
            'first_name', 'new_attribute'
          ])).to eq({
            only: ['first_name'],
            include: {}
          })
        end
      end

      context "with association" do
        it "should add 'include' option and 'only' for association attribute" do
          expect(@feature.includes_for_dot_keys(contact_klass, [
            'emails.0.address', 'first_name', 'last_name'
          ])).to eq({
            only: ['first_name', 'last_name'],
            include: {
              emails: {
                only: ["address"],
                include: {}
              }
            }
          })
        end

        keys = ['first_name']

        {
          "name only" => "emails",
          "index without attributes" => "emails.0",
          "and invalid attribute" => "emails.0.invalid_attribute",
        }.each do |con_name, key|
          context con_name do
            it "should add association with empty include" do
              expect(@feature.includes_for_dot_keys(contact_klass, keys.push(key))).to eq({
                only: ['first_name'],
                include: {
                  emails: {
                    only: [],
                    include: {}
                  }
                }
              })
            end
          end
        end

        context "having attachment" do
          it "should add attachment include on association" do
            expect(@feature.includes_for_dot_keys(contact_klass, [
              'first_name', 'emails.0.address', 'emails.0.documents'
            ])).to eq({
              only: ['first_name'],
              include: {
                emails: {
                  only: ["address"],
                  include: {
                    documents: Dynamic::Base.active_storage_includes
                  }
                }
              }
            })
          end
        end
      end

      context "with attachment" do
        it "should add attachment on include" do
          expect(@feature.includes_for_dot_keys(contact_klass, [
            'first_name', 'photo'
          ])).to eq({
            only: ['first_name'],
            include: {
              photo: Dynamic::Base.active_storage_includes
            }
          })
        end
      end
    end

    context "nested keys" do
      context "on association" do
        let(:company_klass) { "D::Uneek::Company".safe_constantize }

        context "attributes" do
          it "should add include on nested association and add 'only' for deepest association attribute" do
            expect(@feature.includes_for_dot_keys(company_klass, [
              'employees.1.first_name', 'employees.0.emails.0.address', 'name'
            ])).to eq({
              only: ["name"],
              include: {
                employees: {
                  only: ["first_name"],
                  include: {
                    emails: {
                      only: ["address"],
                      include: {}
                    }
                  }
                }
              }
            })
          end
        end

        context "attachments" do
          it "should add include on nested association and add attachment include" do
            expect(@feature.includes_for_dot_keys(company_klass, [
              'name', 'employees.1.first_name', 'employees.0.emails.0.documents'
            ])).to eq({
              only: ["name"],
              include: {
                employees: {
                  only: ["first_name"],
                  include: {
                    emails: {
                      only: [],
                      include: {
                        documents: Dynamic::Base.active_storage_includes
                      }
                    }
                  }
                }
              }
            })
          end
        end
      end

    end
  end
end
