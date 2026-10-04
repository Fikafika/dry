describe Dynamic::Period::Period, elasticsearch: false, sidekiq: false do
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
          associations_attributes: [
            {
              id: '019c678d-1468-7e2d-8f0a-cff68c96c271',
              name: 'periode_precedente',
              schema_id: '019c4dda-3500-7292-8a81-f78b3b1f671f', # why needed ?
              inverse_of_id: '019c678d-2bd8-753d-8bdc-49fdce309073',
              target_klass_id: '019c4d1d-5570-7571-af70-1872d006128a',
              type: 'BelongsTo',
            },
            {
              id: '019c678d-2bd8-753d-8bdc-49fdce309073',
              name: 'periode_suivante',
              schema_id: '019c4dda-3500-7292-8a81-f78b3b1f671f', # why needed ?
              inverse_of_id: '019c678d-1468-7e2d-8f0a-cff68c96c271',
              target_klass_id: '019c4d1d-5570-7571-af70-1872d006128a',
              type: 'BelongsTo',
            },
            {
              id: '019edff3-4e48-78bd-ab32-d97102832da9',
              name: 'semaine',
              schema_id: '019c4dda-3500-7292-8a81-f78b3b1f671f', # why needed ?
              target_klass_id: '019edff0-9310-73a9-b294-d90b70ddfe3e',
              type: 'BelongsTo',
            },
            {
              id: '019c6b3e-f8d8-722d-bb8a-1535132aa5fd',
              name: 'mois',
              schema_id: '019c4dda-3500-7292-8a81-f78b3b1f671f', # why needed ?
              target_klass_id: '019c6b37-cce8-7363-9d94-ae9303e279b5',
              type: 'BelongsTo',
            },
            {
              id: '019edff4-2cf0-7fa5-81ac-b6e13dc1bdf6',
              name: 'trimestre',
              schema_id: '019c4dda-3500-7292-8a81-f78b3b1f671f', # why needed ?
              target_klass_id: '019edff2-8ee0-7807-99fa-cf4edaf250b9',
              type: 'BelongsTo',
            },
            {
              id: '019edff4-4848-7682-9241-5b723be04030',
              name: 'semestre',
              schema_id: '019c4dda-3500-7292-8a81-f78b3b1f671f', # why needed ?
              target_klass_id: '019edff2-cd60-7622-9527-268e21dbb599',
              type: 'BelongsTo',
            },
            {
              id: '019c6b3f-6e08-7b33-99d7-133de504bd7f',
              name: 'annee',
              schema_id: '019c4dda-3500-7292-8a81-f78b3b1f671f', # why needed ?
              target_klass_id: '019c6b39-18f0-72ce-9e73-ddb5234eaac4',
              type: 'BelongsTo',
            }
          ],
        },
        {
          id: '019edff0-9310-73a9-b294-d90b70ddfe3e',
          name: 'SemaineUnitaire',
          attrs_attributes: [
            {
              id: '019edff0-aa80-7530-9fe2-d94122d1ca95',
              name: 'numero',
              type: 'Integer',
            },
          ],
        },
        {
          id: '019c6b37-cce8-7363-9d94-ae9303e279b5',
          name: 'MoisUnitaire',
          attrs_attributes: [
            {
              id: '019c6b38-70f8-77fc-b2a1-d80e70a59e82',
              name: 'numero',
              type: 'Integer',
            },
          ],
        },
        {
          id: '019edff2-8ee0-7807-99fa-cf4edaf250b9',
          name: 'Trimestre',
          attrs_attributes: [
            {
              id: '019edff2-aa38-7f80-89c0-4dea28b72f43',
              name: 'numero',
              type: 'Integer',
            },
          ],
        },
        {
          id: '019edff2-cd60-7622-9527-268e21dbb599',
          name: 'Semestre',
          attrs_attributes: [
            {
              id: '019edff2-e0e8-790b-8910-7e737b59af1e',
              name: 'numero',
              type: 'Integer',
            },
          ],
        },
        {
          id: '019c6b39-18f0-72ce-9e73-ddb5234eaac4',
          name: 'Annee',
          attrs_attributes: [
            {
              id: '019c6b39-3060-706b-b78f-ad41fc112ad0',
              name: 'numero',
              type: 'Integer',
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
            },
            {
              name: 'previous_period',
              value: '019c678d-1468-7e2d-8f0a-cff68c96c271',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
            {
              name: 'week',
              value: '019edff3-4e48-78bd-ab32-d97102832da9',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
            {
              name: 'week_num',
              value: '019edff0-aa80-7530-9fe2-d94122d1ca95',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
            {
              name: 'month',
              value: '019c6b3e-f8d8-722d-bb8a-1535132aa5fd',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
            {
              name: 'month_num',
              value: '019c6b38-70f8-77fc-b2a1-d80e70a59e82',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
            {
              name: 'quarter',
              value: '019edff4-2cf0-7fa5-81ac-b6e13dc1bdf6',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
            {
              name: 'quarter_num',
              value: '019edff2-aa38-7f80-89c0-4dea28b72f43',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
            {
              name: 'half_year',
              value: '019edff4-4848-7682-9241-5b723be04030',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
            {
              name: 'half_year_num',
              value: '019edff2-e0e8-790b-8910-7e737b59af1e',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
            {
              name: 'year',
              value: '019c6b3f-6e08-7b33-99d7-133de504bd7f',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
            {
              name: 'year_num',
              value: '019c6b39-3060-706b-b78f-ad41fc112ad0',
              coder_type: 'Dynamic::Schema::Option::Coder::AttrOrAssocOrAttach',
              type: 'String',
            },
          ],
        },
      ],
    })
    @schema.load
  end

  describe 'create' do

    it 'should be assigned to records with no period' do
      record = D::My::AvisDEcheanceOuFacture.create!(date_pour_paiement: '2026-01-05')
      record.periode.delete # in order to have a date but no period
      expect(record.reload.periode).to eq nil
      period = D::My::Periode.create!(date_debut: '2026-01-01', date_fin: '2026-01-31')
      expect(record.reload.periode).to eq period
    end

    context 'existing next period and previous period' do
      before(:each) do
        @previous = D::My::Periode.create!(date_debut: '2026-01-01', date_fin: '2026-01-31')
        @next = D::My::Periode.create!(date_debut: '2026-03-01', date_fin: '2026-03-31')
      end

      it 'should connect to them' do
        record = D::My::Periode.create!(date_debut: '2026-02-01', date_fin: '2026-02-28')
        expect(record.periode_precedente).to eq @previous
        expect(record.periode_suivante).to eq @next
      end

    end

    context 'week' do
      before(:each) do
        @week= D::My::SemaineUnitaire.create!(numero: 10)
      end

      it 'should be assigned if begin_at and finish_at have the same beginning of the week' do
        period = D::My::Periode.create!(date_debut: '2026-03-02', date_fin: '2026-03-03')
        expect(period.semaine).to eq @week
      end

      it 'should not be assigned if begin_at and finish_at have a different begining of the week' do
        period = D::My::Periode.create!(date_debut: '2026-03-02', date_fin: '2026-03-10')
        expect(period.semaine).to eq nil
      end
    end

    context 'month' do
      before(:each) do
        @month = D::My::MoisUnitaire.create!(numero: 3)
      end

      it 'should be assigned if begin_at and finish_at have same month of same year' do
        period = D::My::Periode.create!(date_debut: '2026-03-01', date_fin: '2026-03-31')
        expect(period.mois).to eq @month
      end

      it 'should not be assigned if begin_at and finish_at have different month/year' do
        period = D::My::Periode.create!(date_debut: '2026-03-01', date_fin: '2026-04-30')
        expect(period.mois).to eq nil
      end
    end

    context 'quarter' do
      before(:each) do
        @quarter = D::My::Trimestre.create!(numero: 1)
      end

      it 'should be assigned if begin_at and finish_at have same quarter of same year' do
        period = D::My::Periode.create!(date_debut: '2026-03-01', date_fin: '2026-03-31')
        expect(period.trimestre).to eq @quarter
      end

      it 'should not be assigned if begin_at and finish_at have different quarter/year' do
        period = D::My::Periode.create!(date_debut: '2026-03-01', date_fin: '2026-04-30')
        expect(period.trimestre).to eq nil
      end
    end

    context 'half year' do
      before(:each) do
        @half_year = D::My::Semestre.create!(numero: 1)
      end

      it 'should be assigned if begin_at and finish_at have same ' do
        period = D::My::Periode.create!(date_debut: '2026-03-01', date_fin: '2026-03-31')
        expect(period.semestre).to eq @half_year
      end

      it 'should not be assigned if begin_at and finish_at have different quarter' do
        period = D::My::Periode.create!(date_debut: '2026-03-01', date_fin: '2026-07-30')
        expect(period.semestre).to eq nil
      end
    end

    context 'half year' do
      before(:each) do
        @year = D::My::Annee.create!(numero: 2026)
      end

      it 'should be assigned if begin_at and finish_at have same year' do
        period = D::My::Periode.create!(date_debut: '2026-03-01', date_fin: '2026-03-31')
        expect(period.annee).to eq @year
      end

      it 'should not be assigned if begin_at and finish_at have different year' do
        period = D::My::Periode.create!(date_debut: '2026-03-01', date_fin: '2027-03-30')
        expect(period.annee).to eq nil
      end
    end

    context 'week, month, quarter, half year, year' do
      before(:each) do
        @week = D::My::SemaineUnitaire.create!(numero: 10)
        @month = D::My::MoisUnitaire.create!(numero: 3)
        @quarter = D::My::Trimestre.create!(numero: 1)
        @half_year = D::My::Semestre.create!(numero: 1)
        @year = D::My::Annee.create!(numero: 2026)
      end

      it 'must be assigned if same week' do
        period = D::My::Periode.create!(date_debut: '2026-03-02', date_fin: '2026-03-03')
        expect(period.semaine).to eq @week
        expect(period.mois).to eq @month
        expect(period.trimestre).to eq @quarter
        expect(period.semestre).to eq @half_year
        expect(period.annee).to eq @year
      end
    end

    context 'with computed finish_at' do
      before(:each) do
        finish_at_attr = @schema.klasses.where(name: 'Periode').first.attrs.where(name: 'date_fin').first
        finish_at_attr.update(formula: 'birthday(date_debut, 1, "m")-1')
        @schema.unload; @schema.load
        @month = D::My::MoisUnitaire.create!(numero: 3)
        @year = D::My::Annee.create!(numero: 2026)
      end

      it 'should compute finish_at and compute month and year' do
        period = D::My::Periode.create!(date_debut: '2026-03-01')
        expect(period.date_fin).to eq Date.parse('2026-03-31')
        expect(period.mois).to eq @month
        expect(period.annee).to eq @year
      end
    end

  end

  describe 'update' do
    before(:each) do
      @period = D::My::Periode.create!(date_debut: '2026-02-01', date_fin: '2026-02-28')
    end

    context 'change begin_at or finish_at' do
      it 'should deassign and create another record' do
        record = D::My::AvisDEcheanceOuFacture.create!(date_pour_paiement: '2026-02-05')
        expect {
          @period.update(date_debut: '2026-03-01')
        }.to change {
          record.reload.periode
        }
        expect(record.periode.date_debut.to_s) == '2026-02-01'
        expect(record.periode.date_fin.to_s) == '2026-02-28'
      end

      it 'should not crash if date is missing in a record' do
        record = D::My::AvisDEcheanceOuFacture.create!
        expect(@period.update(date_debut: '2026-02-10')).to eq true
      end

      context 'existing next period and previous period' do
        before(:each) do
          @previous = D::My::Periode.create!(date_debut: '2026-01-01', date_fin: '2026-01-31')
          @next = D::My::Periode.create!(date_debut: '2026-03-01', date_fin: '2026-03-31')
          @period.reload
          expect(@period.periode_precedente).to eq @previous
          expect(@period.periode_suivante).to eq @next

          @new_previous = D::My::Periode.create!(date_debut: '2026-04-01', date_fin: '2026-04-30')
          @new_next = D::My::Periode.create!(date_debut: '2026-06-01', date_fin: '2026-06-30')
        end

        it 'should update them' do
          @period.update(date_debut: '2026-05-01', date_fin: '2026-05-31')

          expect(@period.periode_precedente).to eq @new_previous
          expect(@period.periode_suivante).to eq @new_next
        end

      end

    end

  end

  describe 'destroy' do
    it 'should be removed from records' do
      record = D::My::AvisDEcheanceOuFacture.create!(date_pour_paiement: '2026-01-05')
      expect {
        record.periode.destroy
      }.to change {
        record.reload.periode
      }.to(nil)
    end
  end

end
