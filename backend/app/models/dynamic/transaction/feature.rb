module Dynamic
  module Transaction
    module Feature; extend Dynamic::Feature

      DEPENDENCIES = [
        'Dynamic::Product::Feature',
        'Dynamic::Amount::Feature',
      ].freeze

      def self.feature_attributes
        {
          name: 'Dynamic::Transaction::Feature',
          human_name_en: 'Transactions management',
          human_name_fr: 'Gestion des transactions',
          mandatory: false,
          enabled: false,
          concerns_attributes: [
            {
              name: 'Base',
              human_name_fr: 'Base',
              human_name_en: 'Base',
              options_attributes: [
                {
                  name: 'convert_until_attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  visible: false,
                  value: ''
                },
                {
                  name: 'emit_date_attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  visible: false,
                  value: ''
                },
                {
                  name: 'transaction_lines_association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  visible: false,
                  value: ''
                },
                {
                  name: 'amount_including_vat_attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  visible: false,
                  value: ''
                },
                {
                  name: 'amount_excluding_vat_attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  visible: false,
                  value: ''
                },
                {
                  name: 'vat_amount_attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  visible: false,
                  value: ''
                },
              ]
            },
            {
              name: 'Line::Base',
              human_name_fr: 'Ligne de transaction',
              human_name_en: 'Transaciton line',
            },
            {
              name: 'Line::Group',
              human_name_fr: 'Ligne de transaction (Groupe)',
              human_name_en: 'Transaciton line (Group)',
            },
            {
              name: 'Line::Info',
              human_name_fr: 'Ligne de transaction (Info)',
              human_name_en: 'Transaciton line (Info)',
            },
            {
              name: 'Quote',
              human_name_fr: 'Devis',
              human_name_en: 'Quote',
              options_attributes: [
                {
                  name: 'orders_association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  visible: false,
                  global: false,
                  value: ''
                },
              ]
            },
            {
              name: 'Order',
              human_name_fr: 'Commande',
              human_name_en: 'Order',
              options_attributes: [
                {
                  name: 'invoices_association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  visible: false,
                  global: false,
                  value: ''
                },
              ]
            },
            {
              name: 'Invoice',
              human_name_fr: 'Facture',
              human_name_en: 'Invoice',
            },
            {
              name: 'AppliedAmount',
              human_name_fr: 'Montant appliqué',
              human_name_en: 'Applied amount',
            },
            {
              name: 'InvoiceSchedule',
              human_name_fr: 'Echéancier de facturation',
              human_name_en: 'Invoice schedule',
            },
            {
              name: 'InvoiceDueDate',
              human_name_fr: 'Echéance de facturation',
              human_name_en: 'Invoice due date',
              options_attributes: [
                {
                  name: 'begin_attribute',
                  human_name_fr: 'Attribut date de début',
                  human_name_en: 'Start date attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  value: ''
                },
                {
                  name: 'validity_attribute',
                  human_name_fr: 'Attribut validité',
                  human_name_en: 'Validity attribute',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  value: ''
                },
                {
                  name: 'invoice_association',
                  human_name_fr: 'Association facture',
                  human_name_en: 'Invoice association',
                  type: 'String',
                  coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                  global: false,
                  value: ''
                },
                {
                  name: 'in_future_enum_value_id',
                  type: 'String',
                  value: '',
                  visible: false,
                },
                {
                  name: 'ongoing_enum_value_id',
                  type: 'String',
                  value: '',
                  visible: false,
                },
                {
                  name: 'past_enum_value_id',
                  type: 'String',
                  value: '',
                  visible: false,
                },
              ]
            },
          ],
          options_attributes: [
            {
              name: 'contact_klass',
              human_name_fr: 'Table des contacts',
              human_name_en: 'Contact Table',
              type: 'String',
              coder_type: 'Dynamic::Schema::Option::Coder::Klass',
              value: nil
            },
            {
              name: 'transaction_line_form_id',
              type: 'Boolean',
              visible: false,
              value: false
            }
          ]
        }
      end

      def self.load(schema)
        Dynamic::Transaction::ApplicableAmount::Rule.mount(schema)
        Dynamic::Transaction::ApplicableAmount::Condition.mount(schema)
        Dynamic::Transaction::ApplicableAmount::Condition.configure_renaming_for(schema)
      end

      def self.after_enabled(feature)
        DEPENDENCIES.each do |d|
          dependency = feature.schema.features.find_by!(name: d)
          unless dependency.enabled
            feature.errors.add :enabled, :dependent, name: dependency.human_name
            raise ActiveRecord::RecordInvalid.new(feature)
          end
        end

        product_feature = feature.schema.features.find_by(name: 'Dynamic::Product::Feature')
        account_klass = product_feature.options.detect {|f| f.name == 'account_klass'}.value
        contact_klass = feature.options.detect {|f| f.name == 'contact_klass'}.value
        product_klass = feature.schema.klasses.detect {|k| k.name == 'Product'}
        product_property_value_klass = feature.schema.klasses.detect {|k| k.name == 'ProductPropertyValue'}
        article_klass = product_feature.concerns.detect {|k| k.name == 'Article'}.klass
        amount_klass = feature.schema.klasses.detect {|k| k.name == 'Amount'}
        vat_klass = feature.schema.klasses.detect {|k| k.name == 'Vat'}

        fee_klass = self.create_fee_klass(feature.schema, amount_klass, vat_klass)

        discount_klass = self.create_discount_klass(feature.schema, amount_klass)

        applied_amount_klass = feature.schema.klasses.detect {|k| k.name == 'AppliedAmount'} || self.create_applied_amount_klass(feature.schema, amount_klass)

        applied_amount_concern = feature.concerns.detect {|c| c.name == 'AppliedAmount'}
        applied_amount_concern.update!(klass: applied_amount_klass) unless applied_amount_concern.klass

        self.create_klasses(feature, account_klass, article_klass, amount_klass, vat_klass, contact_klass, applied_amount_klass)

        self.create_price_and_vat_rate(product_klass, vat_klass)
        self.create_discount_and_fee_associations(product_klass, fee_klass, discount_klass)

        transaction_klass = feature.concerns.detect {|c| c.name == 'Base'}.klass
        self.create_applied_discount_and_fee_associations(transaction_klass, applied_amount_klass)
        applied_amount_klass.associations.create_with( # FIXME should only accepts Transaction and TransactionLine
          human_name_fr: 'Propriétaire',
          human_name_en: 'Owner',
          type: 'BelongsTo',
        ).find_or_create_by!(name: 'owner')

        [product_property_value_klass, article_klass].each do |k|
          self.create_amount_attributes(k)
          self.create_price_and_vat_rate(k, vat_klass)
          self.create_discount_and_fee_associations(k, fee_klass, discount_klass)

          self.create_vat_computable_concern_for_klass(
            feature.schema,
            k,
            {
              'price' => k.attrs.detect {|a| a.name == 'gross_unit_price'},
              'vat_rate' => k.associations.detect {|a| a.name == 'vat_rate'},
              'amount_excluding_vat' => k.attrs.detect {|a| a.name == 'amount_excluding_vat'},
              'amount_including_vat' => k.attrs.detect {|a| a.name == 'amount_including_vat'},
              'vat_amount' => k.attrs.detect {|a| a.name == 'vat_amount'},
            }
          )
        end
      end

      def self.after_enabled_and_commit_schema(feature)
        transaction_concern = feature.concerns.detect {|c| c.name == 'Base'}
        convert_until_option = transaction_concern.options.detect {|o| o.name == 'convert_until_attribute'}

        actions_to_target = [Dynamic::Form::ACTIONS_TO_I[:new], Dynamic::Form::ACTIONS_TO_I[:edit]]
        sub_transaction_concerns = feature.concerns.select {|c| c.name.in?(['Quote', 'Order'])}
        sub_transaction_concerns.each do |c|
          feature.schema.forms.where(actions: actions_to_target, klass_name: c.klass.const_absolute_name).each do |form|
            form.elements.where(attribute_name: convert_until_option.value.name).each do |elem|
              elem.update!(editor: 'step')
            end
          end
        end

        invoice_klass = feature.concerns.detect {|c| c.name == 'Invoice'}.klass
        feature.schema.forms.where(actions: actions_to_target, klass_name: invoice_klass.const_absolute_name).each do |form|
          form.elements.where(attribute_name: convert_until_option.value.name).destroy_all
        end

        self.update_transaction_edit_layout(feature)
        self.update_transaction_line_edit_form(feature)
        self.create_transaction_line_form_and_update_new_layout(feature)
      end

      def self.create_klasses(feature, account_klass, article_klass, amount_klass, vat_klass, contact_klass, applied_amount_klass)
        transaction_concern = feature.concerns.detect {|o| o.name == 'Base'}
        transaction_klass = transaction_concern.klass

        unless transaction_klass
          transaction_klass = self.create_transaction_klass(feature.schema)
          transaction_concern.update!(klass: transaction_klass, locked: true)
          transaction_concern.options.detect {|o| o.name == 'convert_until_attribute'}.update!(value: transaction_klass.attrs.detect {|a| a.name == 'convert_until'})
          transaction_concern.options.detect {|o| o.name == 'emit_date_attribute'}.update!(value: transaction_klass.attrs.detect {|a| a.name == 'emit_date'})
          transaction_concern.options.detect {|o| o.name == 'amount_excluding_vat_attribute'}.update!(value: transaction_klass.attrs.detect {|a| a.name == 'amount_excluding_vat'})
          transaction_concern.options.detect {|o| o.name == 'amount_including_vat_attribute'}.update!(value: transaction_klass.attrs.detect {|a| a.name == 'amount_including_vat'})
          transaction_concern.options.detect {|o| o.name == 'vat_amount_attribute'}.update!(value: transaction_klass.attrs.detect {|a| a.name == 'vat_amount'})
        end

        transaction_line_concern = feature.concerns.detect {|c| c.name == 'Line::Base'}
        transaction_line_klass = transaction_line_concern.klass

        unless transaction_line_klass
          transaction_line_klasses = self.create_transaction_line_klass(feature.schema)
          transaction_line_concern.update!(klass: transaction_line_klasses[0], locked: true)
          feature.concerns.detect {|c| c.name == 'Line::Group'}.update!(klass: transaction_line_klasses[1], locked: true)
          feature.concerns.detect {|c| c.name == 'Line::Info'}.update!(klass: transaction_line_klasses[2], locked: true)
          transaction_line_klass = transaction_line_klasses[0]
        end

        self.create_price_and_vat_rate(transaction_line_klass, vat_klass)
        self.create_applied_discount_and_fee_associations(transaction_line_klass, applied_amount_klass)

        currency_klass = feature.schema.klasses.detect {|k| k.name == 'Currency'}

        self.create_transaction_currency_associations(transaction_klass, currency_klass)
        self.create_transaction_transaction_line_associations(transaction_klass, transaction_line_klass)
        self.create_transaction_line_article_associations(transaction_line_klass, article_klass)
        self.create_transaction_line_self_associations(transaction_line_klass) # an invoice line can refer to an order line

        quote_concern = feature.concerns.detect {|c| c.name == 'Quote'}
        if quote_concern.klass
          quote_klass = quote_concern.klass
        else
          quote_klass = self.create_quote_klass(feature.schema, transaction_klass)
          quote_concern.update!(klass: quote_klass, locked: true)
        end

        order_concern = feature.concerns.detect {|c| c.name == 'Order'}
        if order_concern.klass
          order_klass = order_concern.klass
        else
          order_klass = self.create_order_klass(feature.schema, transaction_klass)
          order_concern.update!(klass: order_klass, locked: true)
        end

        invoice_concern = feature.concerns.detect {|c| c.name == 'Invoice'}
        if invoice_concern.klass
          invoice_klass = invoice_concern.klass
        else
          invoice_klass = self.create_invoice_klass(feature.schema, transaction_klass)
          invoice_concern.update!(klass: invoice_klass, locked: true)
        end

        self.create_transaction_account_associations(transaction_klass, quote_klass, order_klass, invoice_klass, account_klass, contact_klass)

        invoice_due_date_concern = feature.concerns.detect {|c| c.name == 'InvoiceDueDate'}
        if invoice_due_date_concern.klass
          invoice_due_date_klass = invoice_due_date_concern.klass
        else
          invoice_due_date_klass = self.create_invoice_due_date_klass(feature.schema)
          invoice_due_date_concern.options.detect {|opt| opt.name == 'begin_attribute'}.update!(value: invoice_due_date_klass.attrs.detect {|a| a.name == 'scheduled_date'}&.id)
          validity_opt = invoice_due_date_concern.options.detect {|opt| opt.name == 'validity_attribute'}
          attr = self.create_validity_enum_attribute(invoice_due_date_klass)
          validity_opt.update!(value: attr)
          invoice_due_date_concern.options.detect {|opt| opt.name == 'in_future_enum_value_id'}.update!(value: attr.values.detect {|e| e.name == 'in_future'}&.uuid)
          invoice_due_date_concern.options.detect {|opt| opt.name == 'ongoing_enum_value_id'}.update!(value: attr.values.detect {|e| e.name == 'ongoing'}&.uuid)
          invoice_due_date_concern.options.detect {|opt| opt.name == 'past_enum_value_id'}.update!(value: attr.values.detect {|e| e.name == 'past'}&.uuid)
          invoice_due_date_concern.update!(klass: invoice_due_date_klass, locked: true)
        end

        invoice_schedule_concern = feature.concerns.detect {|c| c.name == 'InvoiceSchedule'}
        if invoice_schedule_concern.klass
          invoice_schedule_klass = invoice_schedule_concern.klass
        else
          invoice_schedule_klass = self.create_invoice_schedule_klass(feature.schema)
          invoice_schedule_concern.update!(klass: invoice_schedule_klass, locked: true)
        end

        self.create_invoice_schedule_associations(order_klass, invoice_klass, quote_klass, invoice_schedule_klass, invoice_due_date_klass, transaction_line_klass)
        invoice_due_date_concern.options.detect {|opt| opt.name == 'invoice_association'}&.update!(value: invoice_due_date_klass.associations.detect {|a| a.name == 'invoice'}&.id)

        transaction_lines_opt = transaction_concern.options.detect {|o| o.name == 'transaction_lines_association'}
        unless transaction_lines_opt.value
          transaction_lines_opt.update!(value: transaction_klass.associations.detect {|a| a.name == 'transaction_lines'})
        end

        self.create_quotes_orders_associations(quote_klass, order_klass)

        orders_association_opt = quote_concern.options.detect {|o| o.name == 'orders_association'}
        unless orders_association_opt.value
          orders_association_opt.update!(value: quote_klass.associations.detect {|a| a.name == 'quote_orders'})
        end

        self.create_orders_invoices_associations(order_klass, invoice_klass)

        invoices_association_opt = order_concern.options.detect {|o| o.name == 'invoices_association'}
        unless invoices_association_opt.value
          invoices_association_opt.update!(value: order_klass.associations.detect {|a| a.name == 'invoices'})
        end
      end

      def self.create_fee_klass(schema, amount_klass, vat_klass)
        result = schema.klasses.create_with(
          human_name_fr: 'Charge de transaction',
          human_name_en: 'Fee',
          plural_human_name_fr: 'Charges de transaction',
          plural_human_name_en: 'Fees',
          superklass_id: amount_klass.id,
          icon: 'donate',
        ).find_or_create_by!(name: 'Fee')

        result.attrs.create_with(
          type: 'Enum',
          locked: true,
          values_attributes: [
            { name: 'eco_contribution', human_name_en: 'Eco-contribution', human_name_fr: 'Eco-participation' },
            { name: 'shipping_cost', human_name_en: 'Shipping cost', human_name_fr: 'Frais de livraison' },
          ],
          human_name_fr: 'Catégorie',
          human_name_en: 'Category',
        ).find_or_create_by!(name: 'fee_category')

        result.associations.create_with(
          human_name_fr: 'Taux de TVA',
          human_name_en: 'VAT rate',
          type: 'BelongsTo',
          target_klass: vat_klass,
          locked: true
        ).find_or_create_by!(name: 'vat_rate')

        return result
      end

      def self.create_discount_klass(schema, amount_klass)
        result = schema.klasses.create_with(
          human_name_fr: 'Remise de transaction',
          human_name_en: 'Discount',
          plural_human_name_fr: 'Remises de transaction',
          plural_human_name_en: 'Discounts',
          superklass_id: amount_klass.id,
          icon: 'piggy-bank',
        ).find_or_create_by!(name: 'Discount')

        result.attrs.create_with(
          type: 'Enum',
          locked: true,
          values_attributes: [
            { name: 'flaw', human_name_en: 'Flaw', human_name_fr: 'Rabais' },
            { name: 'fidelity', human_name_en: 'Fidelity', human_name_fr: 'Ristourne' },
            { name: 'early_paiement', human_name_en: 'Early paiement', human_name_fr: 'Escompte' },
            { name: 'clearance', human_name_en: 'Clearance', human_name_fr: 'Solde' },
          ],
          human_name_fr: 'Catégorie',
          human_name_en: 'Category',
        ).find_or_create_by!(name: 'discount_category')

        return result
      end

      def self.create_applied_amount_klass(schema, amount_klass)
        schema.klasses.create!(
          human_name_fr: 'Montant appliqué',
          human_name_en: 'Applied Amount',
          plural_human_name_fr: 'Montants appliqués',
          plural_human_name_en: 'Applied Amount',
          icon: 'equals',
          superklass_id: amount_klass.id,
          update_menu_items: false,
          comment: 'Correspond aux remises ou charges calculées et positionnées pour une ligne de transaction ou une transaction',
          attrs_attributes: [
            {
              type: 'Integer',
              name: 'position',
              human_name_fr: 'Position',
              human_name_en: 'Position',
              locked: true,
            },
            {
              type: 'Enum',
              name: 'applicability',
              human_name_fr: "Mode d'application",
              human_name_en: 'Applicability',
              values_attributes: [
                {
                  name: 'on_base',
                  human_name_fr: "Sur la base",
                  human_name_en: 'On base',
                },
                {
                  name: 'previous_operation',
                  human_name_fr: 'Calcul précédent',
                  human_name_en: 'Previous operation',
                }
              ],
            },
          ],
        )
      end

      def self.create_amount_attributes(klass)
        raw_data = [
          {
            type: 'Float',
            name: 'amount_including_vat',
            human_name_fr: 'Total TTC',
            human_name_en: 'Total amount including VAT',
            comment: 'Calculé implicitement',
            locked: true,
          },
          {
            type: 'Float',
            name: 'amount_excluding_vat',
            human_name_fr: 'Total HT',
            human_name_en: 'Total amount excluding VAT',
            comment: 'Calculé implicitement',
            locked: true,
          },
          {
            type: 'Float',
            name: 'vat_amount',
            human_name_fr: 'Total TVA',
            human_name_en: 'VAT amount',
            comment: 'Calculé implicitement',
            locked: true,
          },
        ]

        raw_data.each do |attrs|
          klass.attrs.create_with(attrs).find_or_create_by!(name: attrs[:name])
        end
      end

      def self.create_transaction_klass(schema)
        schema_const_name = "#{::Dynamic::ROOT_NAME}::#{schema.name}"
        raw_data = {
          name: 'Transaction',
          human_name_fr: 'Transaction',
          human_name_en: 'Transaction',
          plural_human_name_fr: 'Transactions',
          plural_human_name_en: 'Transactions',
          icon: 'money-check-alt',
          table_profile: :huge,
          name_attribute_id: '01a042b3-6058-767f-8168-544a00558ec2',
          update_menu_items: false,
          attrs_attributes: [
            {
              id: '01a042b3-6058-767f-8168-544a00558ec2',
              type: 'String',
              name: 'label',
              human_name_fr: 'Libellé',
              human_name_en: 'Label',
              formula: %Q[
                if(type = "#{schema_const_name}::Quote";
                  reference;
                  if(type = "#{schema_const_name}::Order";
                    reference;
                    if(type = "#{schema_const_name}::Invoice";
                      reference;
                      reference
                    )
                  )
                )
              ]
            },
            {
              type: 'String',
              name: 'reference',
              human_name_fr: 'Référence',
              human_name_en: 'Reference',
            },
            {
              id: '018e845a-0520-7d52-8357-33fee5536e14',
              type: 'Date',
              name: 'emit_date',
              human_name_fr: "Date",
              human_name_en: 'Emit date',
              locked: true,
            },
            {
              type: 'Date',
              name: 'transmission_date',
              human_name_fr: 'Date de transmission',
              human_name_en: 'Transmission date',
            },
            {
              type: 'Date',
              name: 'validity_end',
              human_name_fr: 'Date de fin de validité',
              human_name_en: 'Validity end date',
            },
            {
              type: 'Text',
              name: 'description',
              human_name_fr: 'Description',
              human_name_en: 'Description',
            },
            {
              type: 'Float',
              name: 'amount_including_vat',
              human_name_fr: 'Total TTC',
              human_name_en: 'Total amount including VAT',
              comment: 'Calculé implicitement',
              locked: true,
            },
            {
              type: 'Float',
              name: 'amount_excluding_vat',
              human_name_fr: 'Total HT',
              human_name_en: 'Total amount excluding VAT',
              comment: 'Calculé implicitement',
              locked: true,
            },
            {
              type: 'Float',
              name: 'vat_amount',
              human_name_fr: 'Total TVA',
              human_name_en: 'VAT amount',
              comment: 'Calculé implicitement',
              locked: true,
            },
            {
              type: 'Enum',
              name: 'state',
              human_name_fr: 'Statut',
              human_name_en: 'State',
              locked: true,
              values_attributes: [
                {
                  name: 'created',
                  human_name_fr: 'Créé',
                  human_name_en: 'Created',
                },
                {
                  name: 'requested',
                  human_name_fr: 'Demandé',
                  human_name_en: 'Requested',
                },
                {
                  name: 'validated',
                  human_name_fr: 'Validé',
                  human_name_en: 'Validated',
                },
                {
                  name: 'applied',
                  human_name_fr: 'Appliqué',
                  human_name_en: 'Applied',
                },
                {
                  name: 'canceled',
                  human_name_fr: 'Annulé',
                  human_name_en: 'Canceled',
                },
                {
                  name: 'rejected',
                  human_name_fr: 'Rejeté',
                  human_name_en: 'Rejected',
                },
              ],
            },
            {
              type: 'Enum',
              name: 'convert_until',
              human_name_fr: "Générer jusqu'à",
              human_name_en: 'Generate until',
              locked: true,
              values_attributes: [
                {
                  name: 'order',
                  human_name_fr: 'Commande',
                  human_name_en: 'Order',
                  locked: true,
                },
                {
                  name: 'invoice',
                  human_name_fr: 'Facture',
                  human_name_en: 'Invoice',
                  locked: true,
                },
              ],
            }
          ],
          validations_attributes: [
            {
              name: 'emit_date_presence',
              type: 'Presence',
              attr_id: '018e845a-0520-7d52-8357-33fee5536e14',
              human_name_fr: "Présence de la date d'émission",
              human_name_en: 'Emit date presence',
            },
          ]
        }
        schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
      end

      def self.create_quote_klass(schema, transaction)
        raw_data = {
          name: 'Quote',
          superklass_id: transaction.id,
          human_name_fr: 'Devis',
          human_name_en: 'Quote',
          plural_human_name_fr: 'Devis',
          plural_human_name_en: 'Quotes',
          icon: 'file-alt',
        }
        attrs = Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass, mapping: {transaction.id => transaction.id})
        schema.klasses.create!(attrs)
      end

      def self.create_order_klass(schema, transaction)
        raw_data = {
          name: 'Order',
          superklass_id: transaction.id,
          human_name_fr: 'Commande',
          human_name_en: 'Order',
          plural_human_name_fr: 'Commandes',
          plural_human_name_en: 'Orders',
          icon: 'clipboard-list',
          attrs_attributes: [
            {
              type: 'Enum',
              name: 'order_payment_state',
              human_name_fr: 'Paiment de la commande',
              human_name_en: 'Order payment',
              locked: true,
              values_attributes: [
                {
                  name: 'unpaid',
                  human_name_fr: 'Non payée',
                  human_name_en: 'Unpaid',
                },
                {
                  name: 'partially_paid',
                  human_name_fr: 'Partiellement payée',
                  human_name_en: 'Partially paid',
                },
                {
                  name: 'paid',
                  human_name_fr: 'Payée',
                  human_name_en: 'Paid',
                },
              ]
            },
            {
              type: 'Enum',
              name: 'order_invoice_state',
              human_name_fr: 'Etat de la facturation',
              human_name_en: 'Invoice state',
              locked: true,
              values_attributes: [
                {
                  name: 'none',
                  human_name_fr: 'Aucune',
                  human_name_en: 'None',
                },
                {
                  name: 'partial',
                  human_name_fr: 'Partielle',
                  human_name_en: 'Partial',
                },
                {
                  name: 'complete',
                  human_name_fr: 'Complète',
                  human_name_en: 'Complete',
                },
              ]
            },
          ]
        }
        attrs = Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass, mapping: {transaction.id => transaction.id})
        schema.klasses.create!(attrs)
      end

      def self.create_invoice_due_date_klass(schema)
        raw_data = {
          name: 'InvoiceDueDate',
          human_name_fr: 'Echéance de facturation',
          human_name_en: 'Invoice due date',
          plural_human_name_fr: 'Echéances de facturation',
          plural_human_name_en: 'Invoice due dates',
          icon: 'calendar-check',
          attrs_attributes: [
            {
              id: '018f3344-379c-7fcc-992a-6ae09aa89a10',
              type: 'DateTime',
              name: 'scheduled_date',
              human_name_fr: "Date d'échéance",
              human_name_en: 'Scheduled date',
              locked: true,
            },
            {
              id: '018f3344-379c-7fcc-992a-6ae09aa89a11',
              type: 'Float',
              name: 'amount',
              human_name_fr: 'Montant',
              human_name_en: 'Amount',
              locked: true,
            },
            {
              type: 'Integer',
              name: 'position',
              human_name_fr: 'Position',
              human_name_en: 'Position',
              locked: true,
            },
            {
              type: 'Boolean',
              name: 'canceled',
              human_name_fr: 'Annulé',
              human_name_en: 'Canceled',
              locked: true,
            },
          ],
          validations_attributes: [
            {
              name: 'scheduled_date_presence',
              type: 'Presence',
              attr_id: '018f3344-379c-7fcc-992a-6ae09aa89a10',
              human_name_fr: "Présence de la date de d'échéance",
              human_name_en: 'Schedule date presence',
            },
            {
              name: 'amount_presence',
              type: 'Presence',
              attr_id: '018f3344-379c-7fcc-992a-6ae09aa89a11',
              human_name_fr: 'Présence du montant',
              human_name_en: 'Amount presence',
            },
            {
              name: 'amount_greater_than_zero',
              type: 'Comparison::Value',
              operator: :greater_than,
              comparison_value: 0,
              attr_id: '018f3344-379c-7fcc-992a-6ae09aa89a11',
              human_name_fr: 'Montant supèrieur à zéro',
              human_name_en: 'Amount greater than zero',
            },
          ]
        }
        attrs = Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass)
        return schema.klasses.create!(attrs)
      end

      def self.create_invoice_schedule_klass(schema)
        raw_data = {
          name: 'InvoiceSchedule',
          human_name_fr: 'Echéancier de facturation',
          human_name_en: 'Invoice schedule',
          plural_human_name_fr: 'Echéanciers de facturation',
          plural_human_name_en: 'Invoice schedules',
          icon: 'calendar',
          attrs_attributes: [
            {
              type: 'String',
              name: 'name',
              human_name_fr: 'Nom',
              human_name_en: 'Name',
            },
            {
              type: 'String',
              name: 'line_prefix',
              human_name_fr: 'Préfix de ligne',
              human_name_en: 'line prefix',
              locked: true,
            },
            {
              type: 'DateTime',
              name: 'begin_at',
              human_name_fr: 'Début',
              human_name_en: 'Begin',
              locked: true,
            },
            {
              type: 'DateTime',
              name: 'finish_at',
              human_name_fr: 'Fin',
              human_name_en: 'End',
              locked: true,
            },
            {
              type: 'Boolean',
              name: 'canceled',
              human_name_fr: 'Annulé',
              human_name_en: 'Canceled',
              locked: true,
            },
            {
              type: 'Enum',
              name: 'kind',
              human_name_fr: 'Type',
              human_name_en: 'Type',
              locked: true,
              values_attributes: [
                {
                  name: 'payment_in_installments',
                  human_name_fr: 'Paiement en plusieurs fois',
                  human_name_en: 'Payment in installments',
                },
                {
                  name: 'subscription',
                  human_name_fr: 'Abonnement',
                  human_name_en: 'Subscription',
                }
              ]
            },
            {
              type: 'Enum',
              name: 'recurrency',
              human_name_fr: 'Récurrence',
              human_name_en: 'Recurrence',
              locked: true,
              values_attributes: [
                {
                  name: 'daily',
                  human_name_fr: 'Journalier',
                  human_name_en: 'Daily',
                },
                {
                  name: 'weekly',
                  human_name_fr: 'Hebdomadaire',
                  human_name_en: 'Weekly',
                },
                {
                  name: 'monthly',
                  human_name_fr: 'Mensuel',
                  human_name_en: 'Monthly',
                },
                {
                  name: 'yearly',
                  human_name_fr: 'Annuel',
                  human_name_en: 'Yearly',
                },
              ]
            },
            {
              type: 'Float',
              name: 'amount',
              human_name_fr: 'Montant',
              human_name_en: 'Amount',
              comment: "Est calculé implicitement si un Montant maximum par échéance ou un Nombre d'échéance est spécifié lors de la création",
              locked: true,
            },
            {
              type: 'Float',
              name: 'max_amount_per_due_date',
              human_name_fr: 'Montant maximum par échéance',
              human_name_en: 'Maximum amount per due date',
              locked: true,
            },
            {
              type: 'Integer',
              name: 'due_date_count',
              human_name_fr: "Nombre d'échéance",
              human_name_en: 'Amount of due date',
              locked: true,
            },
            {
              type: 'Integer',
              name: 'weekday_number',
              human_name_fr: 'Jour de la semaine',
              human_name_en: 'Wekkday',
            },
            {
              type: 'Integer',
              name: 'monthday_number',
              human_name_fr: 'Jour du mois',
              human_name_en: 'Day of month',
            },
            {
              type: 'Integer',
              name: 'month_number',
              human_name_fr: 'Mois',
              human_name_en: 'Month',
            },
          ],
        }
        attrs = Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass)
        return schema.klasses.create!(attrs)
      end

      def self.create_invoice_klass(schema, transaction)
        raw_data = {
          name: 'Invoice',
          superklass_id: transaction.id,
          human_name_fr: 'Facture',
          human_name_en: 'Invoice',
          plural_human_name_fr: 'Factures',
          plural_human_name_en: 'Invoices',
          icon: 'clipboard-check',
          attrs_attributes: [
            {
              type: 'Float',
              name: 'unpaid_amount',
              human_name_fr: 'Solde',
              human_name_en: 'Unpaid amount',
              locked: true,
            },
            {
              type: 'Float',
              name: 'paid_amount',
              human_name_fr: 'Montant payé',
              human_name_en: 'Paid amount',
              locked: true,
            },
            {
              type: 'Enum',
              name: 'invoice_status',
              human_name_fr: 'Statut de la facture',
              human_name_en: 'Invoice status',
              locked: true,
              values_attributes: [
                {
                  id: '018f3344-379c-7fcc-992a-6ae09aa89a0e',
                  human_name_fr: 'Partiellement payé(e)',
                  human_name_en: 'Partially paid',
                },
                {
                  id: '018f3344-4be8-78d7-8502-5a1ebe29222e',
                  human_name_fr: 'Payé(e)',
                  human_name_en: 'Paid',
                },
                {
                  id: '018f3344-656f-7b83-823b-d73b13c98a52',
                  human_name_fr: 'Non payé',
                  human_name_en: 'Unpaid',
                }
              ]
            },
            {
              type: 'Enum',
              name: 'invoice_type',
              human_name_fr: 'Code de type de facture',
              human_name_en: 'Invoice type code',
              locked: true,
              values_attributes: [
                { name: '380', human_name_fr: 'Facture commerciale', human_name_en: 'Commercial invoice' },
                { name: '389', human_name_fr: 'Facture auto-facturée', human_name_en: 'Self-billed invoice' },
                { name: '393', human_name_fr: 'Facture affacturée', human_name_en: 'Factored invoice' },
                { name: '501', human_name_fr: 'Facture auto-facturée affacturée', human_name_en: 'Self-billed factored invoice' },
                { name: '386', human_name_fr: "Facture d'acompte", human_name_en: 'Pre-payment invoice' },
                { name: '500', human_name_fr: "Facture d'acompte auto-facturée", human_name_en: 'Self-billed pre-payment invoice' },
                { name: '384', human_name_fr: 'Facture rectificative', human_name_en: 'Corrected invoice' },
                { name: '471', human_name_fr: 'Facture rectificative auto-facturée', human_name_en: 'Self-billed corrected invoice' },
                { name: '472', human_name_fr: 'Facture rectificative affacturée', human_name_en: 'Factored corrected invoice' },
                { name: '473', human_name_fr: 'Facture rectificative auto-facturée affacturée', human_name_en: 'Self-invoiced corrected invoice invoiced by a third party' },
                { name: '261', human_name_fr: 'Avoir auto-facturée', human_name_en: 'Self-billed credit note' },
                { name: '262', human_name_fr: 'Avoir pour Remise Globale', human_name_en: 'Credit note for Global Allowance' },
                { name: '381', human_name_fr: 'Avoir', human_name_en: 'Credit note' },
                { name: '396', human_name_fr: 'Avoir affacturé', human_name_en: 'Factored credit note' },
                { name: '502', human_name_fr: 'Avoir auto-facturé affacturé', human_name_en: 'Factored self-billed credit note' },
                { name: '503', human_name_fr: "Avoir de facture d'acompte", human_name_en: 'Pre-payment credit note' }
              ]
            },
          ]
        }
        attrs = Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass, mapping: {transaction.id => transaction.id})
        schema.klasses.create!(attrs)
      end

      def self.create_transaction_line_klass(schema)
        raw_data = [
          {
            id: '018f3344-656f-7b83-823b-d73b13c99952',
            name: 'TransactionLine',
            human_name_fr: 'Ligne de transaction',
            human_name_en: 'Transaction line',
            plural_human_name_fr: 'Lignes de transaction',
            plural_human_name_en: 'Transaction lines',
            icon: 'th-list',
            table_profile: :large,
            name_attribute_id: '01a042ad-f988-7753-8421-7cc634afc319',
            options_for_indexed_json: {
              'only' => ['label', 'invoiced_quantity', 'base_quantity_for_unit_price', 'unit', 'position', 'net_unit_price', 'amount_excluding_vat', 'amount_including_vat', 'vat_amount'],
              'include' => {
                'parent' => {'only' => ['id', 'label', 'type', 'created_at', 'updated_at', 'deleted_at']},
                'owner_transaction' => {'only' => ['id', 'label', 'type', 'created_at', 'updated_at', 'deleted_at']},
              }
            }.with_indifferent_access,
            update_menu_items: false,
            attrs_attributes: [
              {
                id: '01a042ad-f988-7753-8421-7cc634afc319',
                type: 'String',
                name: 'label',
                human_name_fr: 'Libellé',
                human_name_en: 'Label',
                comment: "Est calculé à partir de l'article associé lors de la création, sauf si renseigné",
              },
              {
                type: 'Integer',
                name: 'position',
                human_name_fr: 'Position',
                human_name_en: 'Position',
                locked: true,
              },
              {
                type: 'Float',
                name: 'invoiced_quantity',
                human_name_fr: 'Quantité',
                human_name_en: 'Quantity',
                comment: 'Peut être modifié automatiquement si le parent est un regroupement (voir Quantité par ligne Parent)',
                locked: true,
              },
              {
                type: 'Float',
                name: 'base_quantity_for_unit_price',
                human_name_fr: 'Quantité de base du Prix Unitaire',
                human_name_en: 'Base quantity for Unit Price',
                locked: true,
              },
              {
                type: 'Float',
                name: 'quantity_for_single_unit_of_parent_line',
                human_name_fr: "Quantité par ligne Parent",
                human_name_en: 'Quantity per Parent line',
                comment: 'Lorsque la ligne a pour parent un regroupement, la quantité sera calculé ainsi :\n quantité du parent * quantité par ligne Parent',
                locked: true,
              },
              {
                type: 'String',
                name: 'unit',
                human_name_fr: 'Unité',
                human_name_en: 'Unit',
              },
              {
                human_name_fr: 'Prix unitaire net',
                human_name_en: 'Net Unit price',
                name: 'net_unit_price',
                type: 'Float',
                comment: 'Correspond au prix unitaire brut soustrait du rabais (voir catégorie de Remise)',
              },
              {
                type: 'Float',
                name: 'amount_excluding_vat',
                human_name_fr: 'Total HT',
                human_name_en: 'Total amount excluding VAT',
                comment: 'Prix unitaire net * Quantité - remises + charges',
                locked: true,
              },
              {
                type: 'Float',
                name: 'amount_including_vat',
                human_name_fr: 'Total TTC',
                human_name_en: 'Total amount including VAT',
                comment: 'Total HT + Total TVA',
                locked: true,
              },
              {
                type: 'Float',
                name: 'vat_amount',
                human_name_fr: 'Total TVA',
                human_name_en: 'VAT amount',
                comment: 'Total HT * Taux de TVA -> pourcentage',
                locked: true,
              },
            ]
          },
          {
            name: 'TransactionLineGroup',
            superklass_id: '018f3344-656f-7b83-823b-d73b13c99952',
            human_name_fr: 'Ligne de transaction de groupement',
            human_name_en: 'Transaction line group',
            plural_human_name_fr: 'Lignes de transaction de groupement',
            plural_human_name_en: 'Transaction lines group',
          },
          {
            name: 'TransactionLineInfo',
            superklass_id: '018f3344-656f-7b83-823b-d73b13c99952',
            human_name_fr: 'Ligne de transaction (information)',
            human_name_en: 'Transaction line group (information)',
            plural_human_name_fr: 'Lignes de transaction (information)',
            plural_human_name_en: 'Transaction lines (information)',
            attrs_attributes: [
              {
                name: 'generated',
                type: 'Boolean',
                human_name_fr: 'Généré',
                human_name_en: 'Generated',
                locked: true,
              }
            ],
          },
          {
            name: 'TransactionLineVat',
            superklass_id: '018f3344-656f-7b83-823b-d73b13c99952',
            human_name_fr: 'Ligne de transaction (TVA)',
            human_name_en: 'Transaction line group (VAT)',
            plural_human_name_fr: 'Lignes de transaction (TVA)',
            plural_human_name_en: 'Transaction lines (VAT)',
            update_menu_items: false,
          }
        ]
        schema.klasses.create!(Dynamic::Feature::UuidConverter.replace_ids(raw_data, Dynamic::Schema::Klass))
      end

      def self.create_transaction_account_associations(transaction, quote, order, invoice, account, contact)
        transaction_contact = transaction.associations.create_with(
          human_name_fr: 'Contact Acheteur',
          human_name_en: 'Buyer Contact',
        ).find_or_create_by!(
          name: 'buyer_contact',
          type: 'BelongsTo',
          target_klass: contact,
        )
        contact_transaction = contact.associations.create_with(
          human_name_fr: 'Transactions',
          human_name_en: 'Transactions',
        ).find_or_create_by!(
          name: 'transactions',
          type: 'HasMany',
          target_klass: transaction,
          inverse_of: transaction_contact
        )
        transaction_contact.update!(inverse_of: contact_transaction)

        contact.associations.create_with(
          human_name_fr: 'Devis',
          human_name_en: 'Quotes',
        ).find_or_create_by!(
          name: 'quotes',
          type: 'HasMany',
          target_klass: quote,
          through: contact_transaction,
        )
        contact.associations.create_with(
          human_name_fr: 'Comandes',
          human_name_en: 'Orders',
        ).find_or_create_by!(
          name: 'orders',
          type: 'HasMany',
          target_klass: order,
          through: contact_transaction,
        )
        contact.associations.create_with(
          human_name_fr: 'Factures',
          human_name_en: 'Invoices',
        ).find_or_create_by!(
          name: 'invoices',
          type: 'HasMany',
          target_klass: invoice,
          through: contact_transaction,
        )

        transaction_seller_account = transaction.associations.create_with(
          human_name_fr: 'Etablissement vendeur',
          human_name_en: 'Seller establishment',
        ).find_or_create_by!(
          name: 'seller_company',
          type: 'BelongsTo',
          target_klass: account,
        )

        transaction_buyer_account = transaction.associations.create_with(
          human_name_fr: 'Etablissement acheteur',
          human_name_en: 'Buyer establishment',
        ).find_or_create_by!(
          name: 'buyer_company',
          type: 'BelongsTo',
          target_klass: account,
        )

        account_transactions_sale = account.associations.create_with(
          human_name_fr: 'Transactions de vente',
          human_name_en: 'Sale Transactions',
        ).find_or_create_by!(
          name: 'sale_transactions',
          type: 'HasMany',
          target_klass: transaction,
          inverse_of: transaction_seller_account,
        )
        transaction_seller_account.update(inverse_of: account_transactions_sale)

        account.associations.create_with(
          human_name_fr: 'Devis de vente',
          human_name_en: 'Sale Quotes',
        ).find_or_create_by!(
          name: 'sale_quotes',
          type: 'HasMany',
          target_klass: quote,
          through: account_transactions_sale,
        )
        account.associations.create_with(
          human_name_fr: 'Comandes de vente',
          human_name_en: 'Sale Orders',
        ).find_or_create_by!(
          name: 'sale_orders',
          type: 'HasMany',
          target_klass: order,
          through: account_transactions_sale,
        )
        account.associations.create_with(
          human_name_fr: 'Factures de vente',
          human_name_en: 'Sale Invoices',
        ).find_or_create_by!(
          name: 'sale_invoices',
          type: 'HasMany',
          target_klass: invoice,
          through: account_transactions_sale,
        )

        account_transactions_purchase = account.associations.create_with(
          human_name_fr: "Transactions d'achat",
          human_name_en: 'Purchase Transactions',
        ).find_or_create_by!(
          name: 'purchase_transactions',
          type: 'HasMany',
          target_klass: transaction,
          inverse_of: transaction_buyer_account,
        )
        transaction_buyer_account.update(inverse_of: account_transactions_purchase)

        account.associations.create_with(
          human_name_fr: "Devis d'achat",
          human_name_en: 'Purchase Quotes',
        ).find_or_create_by!(
          name: 'purchase_quotes',
          type: 'HasMany',
          target_klass: quote,
          through: account_transactions_purchase,
        )
        account.associations.create_with(
          human_name_fr: "Comandes d'achat",
          human_name_en: 'Purchase Orders',
        ).find_or_create_by!(
          name: 'purchase_orders',
          type: 'HasMany',
          target_klass: order,
          through: account_transactions_purchase,
        )
        account.associations.create_with(
          human_name_fr: "Factures d'achat",
          human_name_en: 'Purchase Invoices',
        ).find_or_create_by!(
          name: 'purchase_invoices',
          type: 'HasMany',
          target_klass: invoice,
          through: account_transactions_purchase,
        )
      end

      def self.create_transaction_transaction_line_associations(transaction, transaction_line)
        transaction_transaction_lines = transaction.associations.create_with(
          human_name_fr: 'Lignes de transaction',
          human_name_en: 'Transaction lines',
        ).find_or_create_by!(
          name: 'transaction_lines',
          type: 'HasMany',
          target_klass: transaction_line,
        )

        transaction_line_transaction = transaction_line.associations.create_with(
          human_name_fr: 'Transaction',
          human_name_en: 'Transaction',
        ).find_or_create_by!(
          name: 'owner_transaction',
          type: 'BelongsTo',
          target_klass: transaction,
          inverse_of: transaction_transaction_lines,
        )
        transaction_transaction_lines.update(inverse_of: transaction_line_transaction)

        children_transaction_lines = transaction_line.associations.create_with(
          human_name_fr: 'Sous-lignes',
          human_name_en: 'Sublines',
        ).find_or_create_by!(
          name: 'sublines',
          type: 'HasMany',
          target_klass: transaction_line,
        )

        parent_line_transaction = transaction_line.associations.create_with(
          human_name_fr: 'Parent',
          human_name_en: 'Parent',
        ).find_or_create_by!(
          name: 'parent',
          type: 'BelongsTo',
          target_klass: transaction_line,
          inverse_of: children_transaction_lines,
        )
        children_transaction_lines.update(inverse_of: parent_line_transaction)
      end

      def self.create_transaction_currency_associations(transaction, currency)
        transaction.associations.create_with(
          human_name_fr: 'Devise de la transaction',
          human_name_en: "Transaction's currency",
        ).find_or_create_by!(
          name: 'currency',
          type: 'BelongsTo',
          target_klass: currency,
        )

        transaction.associations.create_with(
          human_name_fr: 'Devise de la comptabilité',
          human_name_en: 'VAT accounting currency',
        ).find_or_create_by!(
          name: 'accounting_currency',
          type: 'BelongsTo',
          target_klass: currency,
        )
      end

      def self.create_transaction_line_article_associations(transaction_line, article)
        transaction_line.associations.create_with(
          human_name_fr: 'Article',
          human_name_en: 'Article',
        ).find_or_create_by!(
          name: 'article',
          type: 'BelongsTo',
          target_klass: article,
        )
      end

      def self.create_transaction_line_self_associations(transaction_line)
        transaction_line.associations.create_with(
          human_name_fr: 'Référence',
          human_name_en: 'Reference',
        ).find_or_create_by!(
          name: 'reference',
          type: 'BelongsTo',
          target_klass: transaction_line,
        )
      end

      def self.create_price_and_vat_rate(target, vat)
        target.attrs.create_with(
          human_name_fr: 'Prix unitaire brut',
          human_name_en: 'Gross Unit price',
        ).find_or_create_by!(
          name: 'gross_unit_price',
          type: 'Float',
        )
        target.associations.create_with(
          human_name_fr: 'Taux de TVA',
          human_name_en: 'VAT rate',
        ).find_or_create_by!(
          name: 'vat_rate',
          type: 'BelongsTo',
          target_klass: vat,
        )
      end

      def self.create_discount_and_fee_associations(target, discount, fee)
        target.associations.create_with(
          human_name_fr: 'Remises',
          human_name_en: 'Discounts',
        ).find_or_create_by!(
          name: 'discounts',
          type: 'HasMany',
          target_klass: discount,
        )
        target.associations.create_with(
          human_name_fr: 'Charges',
          human_name_en: 'Fees',
        ).find_or_create_by!(
          name: 'fees',
          type: 'HasMany',
          target_klass: fee,
        )
      end

      def self.create_applied_discount_and_fee_associations(target, applied_amount)
        target.associations.create_with(
          human_name_fr: 'Remises',
          human_name_en: 'Discounts',
        ).find_or_create_by!(
          name: 'discounts',
          type: 'HasMany',
          target_klass: applied_amount,
        )
        target.associations.create_with(
          human_name_fr: 'Charges',
          human_name_en: 'Fees',
        ).find_or_create_by!(
          name: 'fees',
          type: 'HasMany',
          target_klass: applied_amount,
        )
      end

      def self.create_quotes_orders_associations(quote, order)
        quote_orders = quote.associations.create_with(
          human_name_fr: 'Commandes',
          human_name_en: 'Orders',
        ).find_or_create_by!(
          name: 'quote_orders',
          type: 'HasMany',
          target_klass: order,
        )
        order_quotes = order.associations.create_with(
          human_name_fr: 'Devis',
          human_name_en: 'Quotes',
        ).find_or_create_by!(
          name: 'quotes',
          type: 'HasMany',
          target_klass: quote,
          inverse_of: quote_orders,
        )
        quote_orders.update(inverse_of: order_quotes)
      end

      def self.create_orders_invoices_associations(order, invoice)
        orders_invoices = order.associations.create_with(
          human_name_fr: 'Factures',
          human_name_en: 'Invoices',
        ).find_or_create_by!(
          name: 'invoices',
          type: 'HasMany',
          target_klass: invoice,
        )
        invoices_orders = invoice.associations.create_with(
          human_name_fr: 'Commandes',
          human_name_en: 'Orders',
        ).find_or_create_by!(
          name: 'invoice_orders',
          type: 'HasMany',
          target_klass: order,
          inverse_of: orders_invoices,
        )
        orders_invoices.update(inverse_of: invoices_orders)
      end

      def self.create_invoice_schedule_associations(order, invoice, quote, invoice_schedule, invoice_due_date, transaction_line)
        invoice_schedule.associations.create_with(
          human_name_fr: 'Ligne ciblé',
          human_name_en: 'Targeted line',
        ).find_or_create_by!(
          name: 'targeted_line',
          type: 'BelongsTo',
          target_klass: transaction_line,
        )
        quotes_schedule = quote.associations.create_with(
          human_name_fr: 'Echéanciers',
          human_name_en: 'Schedules',
        ).find_or_create_by!(
          name: 'quote_schedules',
          type: 'HasMany',
          target_klass: invoice_schedule,
        )
        invoice_schedule_quote = invoice_schedule.associations.create_with(
          human_name_fr: 'Devis',
          human_name_en: 'Quote',
        ).find_or_create_by!(
          name: 'quote',
          type: 'BelongsTo',
          target_klass: quote,
          inverse_of: quotes_schedule,
        )
        quotes_schedule.update!(inverse_of: invoice_schedule_quote)

        orders_schedule = order.associations.create_with(
          human_name_fr: 'Echéanciers',
          human_name_en: 'Schedules',
        ).find_or_create_by!(
          name: 'order_schedules',
          type: 'HasMany',
          target_klass: invoice_schedule,
        )
        invoice_schedule_order = invoice_schedule.associations.create_with(
          human_name_fr: 'Commande',
          human_name_en: 'Order',
        ).find_or_create_by!(
          name: 'order',
          type: 'BelongsTo',
          target_klass: order,
          inverse_of: orders_schedule,
        )
        orders_schedule.update!(inverse_of: invoice_schedule_order)

        invoice_due_date_invoices = invoice_due_date.associations.create_with(
          human_name_fr: 'Facture',
          human_name_en: 'Invoice',
        ).find_or_create_by!(
          name: 'invoice',
          type: 'BelongsTo',
          target_klass: invoice,
        )
        invoice_invoice_due_date = invoice.associations.create_with(
          human_name_fr: 'Echéances',
          human_name_en: 'Due Dates',
        ).find_or_create_by!(
          name: 'due_dates',
          type: 'HasMany',
          target_klass: invoice_due_date,
          inverse_of: invoice_due_date_invoices,
        )
        invoice_due_date_invoices.update!(inverse_of: invoice_invoice_due_date)

        invoice_schedule_due_dates = invoice_schedule.associations.create_with(
          human_name_fr: 'Echéances',
          human_name_en: 'Due dates',
        ).find_or_create_by!(
          name: 'due_dates',
          type: 'HasMany',
          target_klass: invoice_due_date,
        )
        invoice_due_date_schedule = invoice_due_date.associations.create_with(
          human_name_fr: 'Echéancier',
          human_name_en: 'Schedule',
        ).find_or_create_by!(
          name: 'schedule',
          type: 'BelongsTo',
          target_klass: invoice_schedule,
          inverse_of: invoice_schedule_due_dates,
        )
        invoice_schedule_due_dates.update!(inverse_of: invoice_due_date_schedule)
      end

      def self.create_validity_enum_attribute(klass)
        klass.attrs.create!(
          name: 'validity',
          type: 'Enum',
          human_name_fr: 'Validité',
          human_name_en: 'Validity',
          values_attributes: [
            {
              name: 'in_future',
              human_name_fr: 'A venir',
              human_name_en: 'In future',
              locked: true,
            },
            {
              name: 'ongoing',
              human_name_fr: 'En cours',
              human_name_en: 'Ongoing',
              locked: true,
            },
            {
              name: 'past',
              human_name_fr: 'Passé',
              human_name_en: 'Past',
              locked: true,
            },
          ],
        )
      end

      def self.create_vat_computable_concern_for_klass(schema, klass, mapping)
        amount_feature = schema.features.detect {|f| f.name == 'Dynamic::Amount::Feature'}
        return if amount_feature.concerns.detect {|c| c.name == 'VatComputable' && c.klass == klass}

        ct = amount_feature.concern_templates.detect {|ct| ct.name == 'VatComputable'}
        computable_concern_attrs = ct.slice('human_name_fr', 'human_name_en', 'name')
        computable_concern_attrs.merge!(klass: klass)
        dup_computable_options = ct.options.map do |o|
          o.slice('name', 'human_name_fr', 'human_name_en', 'value', 'type', 'coder_type', 'global')
        end

        dup_computable_options.detect {|o| o['name'] == 'base_amount_attribute'}.merge!('value' => mapping['price']&.id)
        dup_computable_options.detect {|o| o['name'] == 'vat_rate_association'}.merge!('value' => mapping['vat_rate']&.id)
        dup_computable_options.detect {|o| o['name'] == 'amount_excluding_vat_attribute'}.merge!('value' => mapping['amount_excluding_vat']&.id)
        dup_computable_options.detect {|o| o['name'] == 'amount_including_vat_attribute'}.merge!('value' => mapping['amount_including_vat']&.id)
        dup_computable_options.detect {|o| o['name'] == 'vat_amount_attribute'}.merge!('value' => mapping['vat_amount']&.id)
        dup_computable_options.detect {|o| o['name'] == 'quantity_attribute'}.merge!('value' => mapping['quantity']&.id)

        amount_feature.concerns.create!(computable_concern_attrs.merge(options_attributes: dup_computable_options))
      end

      def self.update_transaction_edit_layout(feature)
        ['Base', 'Quote', 'Order', 'Invoice'].each do |c_name|
          transaction_klass = feature.concerns.detect {|o| o.name == c_name}&.klass
          next unless transaction_klass
          edit_layout = feature.schema.layouts.where(klass_name: transaction_klass.const_absolute_name).with_action(:edit).first
          next unless edit_layout

          edit_layout.elements.where(component: 'Crm::Sheet::TabBar::Tab').where("component_params::json->>'name'=?", 'all').destroy_all # destroy "All" tab

          transaction_lines_assoc = transaction_klass.inherited_attrs_assocs_attachs.detect {|a| a.name == 'transaction_lines'} # TODO mapping for name ?
          transaction_lines_tab = edit_layout.elements.where(component: 'Crm::Sheet::TabBar::Tab').where("component_params::json->>'association_id'=?", transaction_lines_assoc.id).first
          next if c_name == 'Base' && transaction_lines_tab.nil?

          if c_name != 'Base' && transaction_lines_tab.nil?
            sheet_tab_bar = edit_layout.elements.where(component: 'Crm::Sheet::TabBar').first
            transaction_lines_tab = sheet_tab_bar.children.create!(transaction_lines_assoc.build_association_tab_attributes)
          end

          unless c_name == 'Base'
            toolbar = transaction_lines_tab.children.detect {|c| c.component == 'Toolbar'}
            if toolbar
              new_item_btn = toolbar.children.detect {|c| c.component == 'Crm::Sheet::NewItemButton'}
              ['Line::Group', 'Line::Info'].each do |tl_name|
                line_klass = feature.concerns.detect {|c| c.name == tl_name}&.klass
                next unless line_klass

                other_attrs = {
                  human_name_fr: "Nouveau #{line_klass.human_name_fr}",
                  human_name_en: "New #{line_klass.human_name_en}",
                  association: "#{transaction_klass.const_absolute_name}.#{transaction_lines_assoc.name}",
                  updated_when_schema_is_changed: false,
                  elements_attributes: [
                    {
                      type: 'Association::BelongsTo',
                      attribute_name: 'parent',
                      klass_name: line_klass.const_absolute_name,
                      root_klass_name: line_klass.const_absolute_name,
                      autocomplete_filters: {
                        'owner_transaction'=>{'contains_id'=>{'variable'=>'owner_transaction'}},
                        'parent'=>{'not_contains_id'=>{'variable'=>'id'}}
                      }
                    },
                    {
                      type: 'Attribute::String',
                      attribute_name: 'label',
                      requirement: :mandatory,
                      klass_name: line_klass.const_absolute_name,
                      root_klass_name: line_klass.const_absolute_name,
                    },
                    {
                      type: 'Attribute::Float',
                      attribute_name: 'invoiced_quantity',
                      klass_name: line_klass.const_absolute_name,
                      root_klass_name: line_klass.const_absolute_name,
                    },
                  ]
                }

                if tl_name == 'Line::Info'
                  other_attrs[:elements_attributes] << {
                    type: 'Attribute::Float',
                    attribute_name: 'gross_unit_price',
                    klass_name: line_klass.const_absolute_name,
                    root_klass_name: line_klass.const_absolute_name,
                  }
                end

                f = Dynamic::Form.create_with(other_attrs).find_or_create_by!(
                  schema: feature.schema,
                  actions: [:new],
                  mode: :input,
                  klass_name: line_klass.const_absolute_name,
                  target_klass_name: transaction_klass.const_absolute_name,
                  source_klass_name: line_klass.const_absolute_name,
                )

                next if new_item_btn.children.where("component_params_converter_options::json->>'form_id'=?", f.id).exists?
                new_item_btn.children.create!(
                  component: 'Toolbar::Dropdown::Item',
                  component_params_converter_type: 'Crm::Sheet::NewItemButton::DropdownItem::ParamsConverter',
                    component_params_converter_options: {
                      form_id: f.id,
                      klass_name: f.klass_name,
                      translations: {
                        fr: { text: f.human_name_fr },
                        en: { text: f.human_name_en },
                      },
                    }
                )
              end
            end
          end

          transaction_lines_tab.children.where(component: 'InfiniteScroller').destroy_all # destroy InfiniteScroller
          unless transaction_lines_tab.children.where(component: 'Crm::TransactionLine::Table').exists?
            transaction_lines_tab.children.create!(
              component: 'Crm::TransactionLine::Table',
              component_params_converter_type: 'Crm::TransactionLine::Table::ParamsConverter',
              component_params: {
                class: 'container-fluid',
                columns: [
                  {
                    name: 'label',
                    width: '100%',
                  },
                  {
                    name: 'invoiced_quantity',
                    human_name_fr: 'Qté',
                    human_name_en: 'Qty',
                    width: '50px',
                  },
                  {
                    name: 'unit',
                    width: '80px',
                  },
                  {
                    name: 'gross_unit_price',
                    width: '80px',
                    format: 'currency',
                  },
                  {
                    name: 'vat_rate.percent',
                    width: '80px',
                    format: 'x100_percentage',
                  },
                  {
                    name: 'compute_discounts',
                    width: '80px',
                    format: 'currency',
                    type: 'Attribute::Float',
                    human_name_fr: 'Remise',
                    human_name_en: 'Discount',
                  },
                  {
                    name: 'amount_excluding_vat',
                    width: '80px',
                    format: 'currency',
                  },
                  {
                    name: 'amount_including_vat',
                    width: '80px',
                    format: 'currency',
                  }
                ],
                lines_association: 'transaction_lines',
                currency_association: 'currency',
                group_column: 'parent_id',
                position_column: 'position',
                amount_excluding_vat_attribute: 'amount_excluding_vat',
                amount_including_vat_attribute: 'amount_including_vat',
                vat_breakdown_attribute: 'compute_vat_breakdown',
                discount_and_fee_summary_attribute: 'compute_fees_and_discounts',
              },
            )
          end
        end
      end

      def self.update_transaction_line_edit_form(feature)
        line_klasses = []
        transaction_klass = feature.concerns.detect {|c| c.name == 'Base'}.klass
        ['Line::Base', 'Line::Group', 'Line::Info'].each do |c_name|
          k = feature.concerns.detect {|o| o.name == c_name}&.klass
          line_klasses << k if k
        end

        line_klasses.each do |line_klass|
          elem_attributes = {
            autocomplete_filters: {
              'owner_transaction'=>{'contains_id'=>{'variable'=>'owner_transaction'}},
              'parent'=>{'not_contains_id'=>{'variable'=>'id'}}
            }
          }

          edit_form = feature.schema.forms.with_action([:edit]).where(klass_name: line_klass.const_absolute_name, default: true).first
          next unless edit_form
          elem = edit_form.elements.detect {|e| e.attribute_name == 'parent'}
          elem.update!(elem_attributes) if elem

          new_for_transaction_form = feature.schema.forms.with_action([:input]).where(
            association_klass_name: transaction_klass.const_absolute_name,
            association_name: 'transaction_lines',
            klass_name: line_klass.const_absolute_name,
            default: true
          ).first
          next unless new_for_transaction_form
          elem = new_for_transaction_form.elements.detect {|e| e.attribute_name == 'parent'}
          elem.update!(elem_attributes) if elem
        end
      end

      def self.create_transaction_line_form_and_update_new_layout(feature)
        option = feature.options.detect {|o| o.name == 'transaction_line_form_id'}
        return if option.value

        product_feature = feature.schema.features.find_by(name: 'Dynamic::Product::Feature')
        article_klass = product_feature.concerns.detect {|k| k.name == 'Article'}.klass
        article_klass_name = article_klass.const_absolute_name
        transaction_line_klass = feature.concerns.detect {|c| c.name == 'Line::Base'}.klass
        transaction_line_klass_name = transaction_line_klass.const_absolute_name
        assoc_name = transaction_line_klass.associations.detect {|a| a.target_klass_id = article_klass.id}&.name
        visible_attr_name = 'visible' # FIXME make an option in Product Feature

        form = feature.schema.forms.create!(
          human_name: 'Nouveau',
          klass_name: transaction_line_klass_name,
          actions: ['new'],
          mode: 'input',
          default: true,
          updated_when_schema_is_changed: false,
          human_name_en: 'New',
          human_name_fr: 'Nouveau',
          elements_attributes:  [
            {
              type: 'Attribute::Boolean',
              editor: 'radio',
              attribute_name: visible_attr_name,
              root_klass_name: transaction_line_klass_name,
              klass_name: transaction_line_klass_name,
              css_classes: {field_size: nil, label_size: nil},
              label_col_size: 'col-md-3',
              input_col_size: 'col-md-9',
              label_en: 'Do you wish to use an existing product ?',
              label_fr: 'Souhaitez-vous reprendre un produit existant ?',
            },
            {
              type: 'Layout::Condition',
              klass_name: transaction_line_klass_name,
              condition_formula: {visible_attr_name => {equal: true}},
              children_attributes: [
                {
                  type: 'Association::BelongsTo',
                  mode: 'nested_form',
                  position: 0,
                  attribute_name: assoc_name,
                  klass_name: transaction_line_klass_name,
                  root_klass_name: transaction_line_klass_name,
                  css_classes: {field_size: nil, label_size: nil},
                  label_col_size: 'col-md-3',
                  input_col_size: 'col-md-9',
                  min: 1,
                  children_attributes: [
                    {
                      type: 'Attribute::String',
                      editor: 'autocomplete',
                      attribute_name: 'name',
                      klass_name: article_klass_name,
                      root_klass_name: transaction_line_klass_name,
                      method_names: [assoc_name],
                      css_classes: {field_size: nil, label_size: nil},
                      label_col_size: 'col-md-3',
                      input_col_size: 'col-md-9',
                    },
                    {
                      type: 'Attribute::Float',
                      attribute_name: 'gross_unit_price',
                      klass_name: article_klass_name,
                      root_klass_name: transaction_line_klass_name,
                      method_names: [assoc_name],
                    },
                  ]
                },
                {
                  type: 'Attribute::Float',
                  attribute_name: 'invoiced_quantity',
                  klass_name: transaction_line_klass_name,
                  root_klass_name: transaction_line_klass_name,
                },
              ]
            },
            {
              type: 'Layout::Condition',
              klass_name: transaction_line_klass_name,
              condition_formula: {visible_attr_name => {equal: false}},
              children_attributes: [
                {
                  type: 'Attribute::String',
                  attribute_name: 'label',
                  klass_name: transaction_line_klass_name,
                  root_klass_name: transaction_line_klass_name,
                },
                {
                  type: 'Attribute::Float',
                  attribute_name: 'gross_unit_price',
                  klass_name: transaction_line_klass_name,
                  root_klass_name: transaction_line_klass_name,
                },
                {
                  type: 'Attribute::String',
                  attribute_name: 'unit',
                  klass_name: transaction_line_klass_name,
                  root_klass_name: transaction_line_klass_name,
                },
                {
                  type: 'Attribute::Float',
                  attribute_name: 'invoiced_quantity',
                  klass_name: transaction_line_klass_name,
                  root_klass_name: transaction_line_klass_name,
                },
                {
                  type: 'Association::BelongsTo',
                  attribute_name: 'vat_rate',
                  klass_name: transaction_line_klass_name,
                  root_klass_name: transaction_line_klass_name,
                },
              ]
            },
          ]
        )
        layout = Dynamic::Layout.with_action(:new).where(klass_name: transaction_line_klass_name).first
        form_component = layout.elements.detect {|e| e.component == 'Form'}
        params = form_component.component_params
        params['dynamic_form_id'] = form.id
        form_component.update!(component_params: params)
        option.update!(value: true)
      end

    end
  end
end
