describe Dynamic::Period::BelongsToPeriod, elasticsearch: false, sidekiq: false do
  context 'monthly_period' do

    before(:each) do
      @schema = Dynamic::Schema.create!({
        id: '019c4dda-3500-7292-8a81-f78b3b1f671f',
        name: 'my',
        klasses_attributes: [
          {
            id: '019c4d0c-2ae8-72e9-9852-f3fc9de3b452',
            name: 'AvisDEcheanceOuFacture',
            attrs_attributes: [
              {
                id: '019c4d1d-b330-78f4-b69f-9bb916735f32',
                name: 'date_pour_paiement',
                type: 'Date',
              },
            ],
            associations_attributes: [
              {
                id: '019c4d1d-ce88-7ae9-8ec5-9637aba2e63f',
                name: 'periode',
                schema_id: '019c4dda-3500-7292-8a81-f78b3b1f671f', # why needed ?
                target_klass_id: '019c4d1d-5570-7571-af70-1872d006128a',
                type: 'BelongsTo',
              }
            ],
          },
          {
            id: '019c4d1d-5570-7571-af70-1872d006128a',
            name: 'Periode',
            attrs_attributes: [
              {
                id: '019c4d1d-e5f8-7fe7-9c5e-423b542200e4',
                name: 'date_debut',
                type: 'Date',
              },
              {
                id: '019c4d1d-fd68-7f53-9111-7bb3e23f4ea8',
                name: 'date_fin',
                type: 'Date',
              },
            ],
          },
        ],
      })
      @schema.features.where(name: 'Dynamic::Period::Feature').first.update({
        enabled: true,
        concerns_attributes: [
          {
            name: 'BelongsToPeriod',
            klass_id: '019c4d0c-2ae8-72e9-9852-f3fc9de3b452',
            options_attributes: [
              {
                name: 'date',
                value: '019c4d1d-b330-78f4-b69f-9bb916735f32',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                type: 'String',
              },
              {
                name: 'monthly_period',
                value: '019c4d1d-ce88-7ae9-8ec5-9637aba2e63f',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                type: 'String',
              },
            ],
          },
          {
            name: 'Period',
            klass_id: '019c4d1d-5570-7571-af70-1872d006128a',
            options_attributes: [
              {
                name: 'begin_at',
                value: '019c4d1d-e5f8-7fe7-9c5e-423b542200e4',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                type: 'String',
              },
              {
                name: 'finish_at',
                value: '019c4d1d-fd68-7f53-9111-7bb3e23f4ea8',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                type: 'String',
              }
            ],
          },
        ],
      })
      @schema.load
    end

    describe 'create' do

      context 'no existing period' do
        it 'should create a period and assign it' do
          record = nil
          expect {
            record = D::My::AvisDEcheanceOuFacture.create!(date_pour_paiement: '2026-01-05')
          }.to change {
            D::My::Periode.count
          }.by(1)
          record.reload
          expect(record.periode).to eq D::My::Periode.last
          expect(record.periode.date_debut.to_s) == '2026-01-01'
          expect(record.periode.date_fin.to_s) == '2026-01-31'
        end
      end

      context 'existing period' do
        before(:each) do
          @existing = D::My::Periode.create!(date_debut: '2026-01-01', date_fin: '2026-01-31')
        end

        it 'should assign period if date is in period' do
          record = nil
          expect {
            record = D::My::AvisDEcheanceOuFacture.create!(date_pour_paiement: '2026-01-05')
          }.to_not change {
            D::My::Periode.count
          }
          expect(record.reload.periode).to eq @existing
        end

        context 'computed date and compute attribute based on period' do
          before(:each) do
            Dynamic::Schema::Attribute::Base.where(name: 'date_pour_paiement').first.update(formula: '"2026-01-05"')
            @schema.klasses.where(name: 'AvisDEcheanceOuFacture').first.attrs.create!(name: 'date_fin', type: 'String', formula: 'periode.date_fin')

            @schema.unload; @schema.load
            @existing = D::My::Periode.find(@existing.id)
          end

          it 'should assign period if date is in period' do
            record = nil
            expect {
              record = D::My::AvisDEcheanceOuFacture.create!
            }.to_not change {
              D::My::Periode.count
            }
            expect(record.reload.periode).to eq @existing
          end

          it 'should compute the attribute based on period' do
            record = D::My::AvisDEcheanceOuFacture.create!
            expect(record.date_fin).to eq '2026-01-31'
          end

        end

      end


      xcontext 'with period nested attributes'

    end

    describe 'update' do

      context 'no existing period' do
        it 'should create and assign it' do
          record = D::My::AvisDEcheanceOuFacture.create!
          record.update(date_pour_paiement: '2026-01-05')
          expect(record.reload.periode).to eq D::My::Periode.last
        end
      end

      context 'existing period' do
        before(:each) do
          @existing = D::My::Periode.create!(date_debut: '2026-01-01', date_fin: '2026-01-31')
        end

        context 'already assigned' do
          it 'should assign nil to period when assign nil to date' do
            record = D::My::AvisDEcheanceOuFacture.create(date_pour_paiement: '2026-01-05')
            expect {
              record.update(date_pour_paiement: nil)
            }.to change {
              record.periode
            }.from(D::My::Periode.last).to(nil)
          end

          it 'should change period when change date' do
            record = D::My::AvisDEcheanceOuFacture.create(date_pour_paiement: '2026-01-05')
            expect {
              record.update(date_pour_paiement: '2026-02-05')
            }.to change {
              record.periode.date_debut.to_s
            }.from('2026-01-01').to('2026-02-01')
          end
        end

        context 'not already assigned' do
          it 'should assign it' do
            record = D::My::AvisDEcheanceOuFacture.create!
            expect {
              record.update(date_pour_paiement: '2026-01-05')
            }.to change {
              record.periode
            }.from(nil).to(@existing)
          end
        end
      end
    end

    describe 'import' do
      before(:each) do
        @import_options = {on_duplicate_key_update: D::My::Periode.column_names - ['created_at', 'updated_at']}
      end

      context 'existing period' do
        before(:each) do
          @existing = D::My::Periode.create!(date_debut: '2026-01-01', date_fin: '2026-01-31')
        end

        it 'should create a period and assign it' do
          expect {
            D::My::AvisDEcheanceOuFacture.import([
              D::My::AvisDEcheanceOuFacture.new(
                id: '019c5105-f980-7aac-9f3c-1b84ee007491',
                date_pour_paiement: '2026-01-05'
              ),
            ], **@import_options)
          }.to_not change {
            D::My::Periode.count
          }
          record = D::My::AvisDEcheanceOuFacture.last
          expect(record.periode).to eq @existing
        end

        it 'should change period when change date' do
          record = D::My::AvisDEcheanceOuFacture.create!(
            id: '019c5105-f980-7aac-9f3c-1b84ee007491',
            date_pour_paiement: '2026-01-05',
          )
          expect {
            record.date_pour_paiement = '2026-02-05'
            D::My::AvisDEcheanceOuFacture.import([record], **@import_options)
          }.to change {
            D::My::Periode.count
          }.by(1)
          expect(record.periode.date_debut.to_s).to eq '2026-02-01'
        end

      end

    end
  end

  context 'monthly_period, yearly_period' do
    before(:each) do
      @schema = Dynamic::Schema.create!({
        id: '019c4dda-3500-7292-8a81-f78b3b1f671f',
        name: 'my',
        klasses_attributes: [
          {
            id: '019c4d0c-2ae8-72e9-9852-f3fc9de3b452',
            name: 'AvisDEcheanceOuFacture',
            attrs_attributes: [
              {
                id: '019c4d1d-b330-78f4-b69f-9bb916735f32',
                name: 'date_pour_paiement',
                type: 'Date',
              },
            ],
            associations_attributes: [
              {
                id: '019c5695-5c38-7f37-bf98-6353c50f43a4',
                name: 'periode_mensuelle',
                schema_id: '019c4dda-3500-7292-8a81-f78b3b1f671f', # why needed ?
                target_klass_id: '019c562f-62c0-72e9-be8c-bd5ba02ebde8',
                type: 'BelongsTo',
              },
              {
                id: '019c5695-7790-7cdb-a3ea-fcb2d6059fee',
                name: 'periode_annuelle',
                schema_id: '019c4dda-3500-7292-8a81-f78b3b1f671f', # why needed ?
                target_klass_id: '019c562f-7648-70df-97b1-d8e7eafb0d12',
                type: 'BelongsTo',
              }
            ],
          },
          {
            id: '019c4d1d-5570-7571-af70-1872d006128a',
            name: 'Periode',
            attrs_attributes: [
              {
                id: '019c4d1d-e5f8-7fe7-9c5e-423b542200e4',
                name: 'date_debut',
                type: 'Date',
              },
              {
                id: '019c4d1d-fd68-7f53-9111-7bb3e23f4ea8',
                name: 'date_fin',
                type: 'Date',
              },
            ],
          },
          {
            id: '019c562f-62c0-72e9-be8c-bd5ba02ebde8',
            superklass_id: '019c4d1d-5570-7571-af70-1872d006128a',
            name: 'PeriodeMensuelle',
          },
          {
            id: '019c562f-7648-70df-97b1-d8e7eafb0d12',
            superklass_id: '019c4d1d-5570-7571-af70-1872d006128a',
            name: 'PeriodeAnnuelle',
          },
        ],
      })
      @schema.features.where(name: 'Dynamic::Period::Feature').first.update({
        enabled: true,
        concerns_attributes: [
          {
            name: 'BelongsToPeriod',
            klass_id: '019c4d0c-2ae8-72e9-9852-f3fc9de3b452',
            options_attributes: [
              {
                name: 'date',
                value: '019c4d1d-b330-78f4-b69f-9bb916735f32',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                type: 'String',
              },
              {
                name: 'monthly_period',
                value: '019c5695-5c38-7f37-bf98-6353c50f43a4',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                type: 'String',
              },
              {
                name: 'yearly_period',
                value: '019c5695-7790-7cdb-a3ea-fcb2d6059fee',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                type: 'String',
              },
            ],
          },
          {
            name: 'Period',
            klass_id: '019c4d1d-5570-7571-af70-1872d006128a',
            options_attributes: [
              {
                name: 'begin_at',
                value: '019c4d1d-e5f8-7fe7-9c5e-423b542200e4',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                type: 'String',
              },
              {
                name: 'finish_at',
                value: '019c4d1d-fd68-7f53-9111-7bb3e23f4ea8',
                coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
                type: 'String',
              }
            ],
          },
        ],
      })
      @schema.load
    end

    describe 'create' do

      context 'existing period' do
        before(:each) do
          @existing_month = D::My::PeriodeMensuelle.create!(date_debut: '2026-01-01', date_fin: '2026-01-31')
          @existing_year = D::My::PeriodeAnnuelle.create!(date_debut: '2026-01-01', date_fin: '2026-12-31')
        end

        it 'should create a period and assign it' do
          record = nil
          expect {
            record = D::My::AvisDEcheanceOuFacture.create!(date_pour_paiement: '2026-01-05')
          }.to_not change {
            D::My::Periode.count
          }
          expect(record.reload.periode_mensuelle).to eq @existing_month
          expect(record.reload.periode_annuelle).to eq @existing_year
        end
      end

      context 'no existing period' do
        it 'should create a period and assign it' do
          record = nil
          expect {
            record = D::My::AvisDEcheanceOuFacture.create!(date_pour_paiement: '2026-01-05')
          }.to change {
            D::My::Periode.count
          }.by(2)
          record.reload
          expect(record.periode_mensuelle.date_debut.to_s) == '2026-01-01'
          expect(record.periode_mensuelle.date_fin.to_s) == '2026-01-31'
          expect(record.periode_annuelle.date_debut.to_s) == '2026-01-01'
          expect(record.periode_annuelle.date_fin.to_s) == '2026-12-31'
        end
      end
    end

  end

end
