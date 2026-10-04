#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

OpenSearch::Model.client.wait_for_server

@schema = Dynamic::Schema.where(name: 'Uneek').first

unless @schema.features.detect{|e| e.name =~ /Dashboard/}
  @schema.create_feature('Dynamic::Dashboard::Feature')
end

def download_ndx
  puts "download ndx"

  require 'open-uri'

  FileUtils.mkdir_p('tmp')

  File.open("tmp/ndx.csv", "wb") do |saved_file|
    # the following "open" is provided by open-uri
    URI.open("https://dc-js.github.io/dc.js/ndx.csv", "rb") do |read_file|
      saved_file.write(read_file.read)
    end
  end
end

@Nasdaq = @schema.klasses.where(name: 'Nasdaq').first
@Nasdaq ||= @schema.klasses.create!(
  id: '0183417a-abe1-70e3-8455-d353e75fbf68',
  human_name_fr: 'Nasdaq',
  human_name_en: 'Nasdaq',
  icon: 'chart-line',
  attrs_attributes: [
    {
      id: '0183417a-afc7-7211-bdf2-8a457baf93aa',
      human_name_fr: 'Date',
      human_name_en: 'Date',
      type: 'Date',
    },
    {
      id: '0183417a-b213-7284-aa1a-9ae9e9f9fd22',
      human_name_fr: 'Ouverture',
      human_name_en: 'Open',
      type: 'Float',
    },
    {
      id: '0183417a-b697-73c1-91f6-15684730bab8',
      human_name_fr: 'Fermeture',
      human_name_en: 'Close',
      type: 'Float',
    },
    {
      id: '0183417a-bab7-727c-b0b3-d393512363d6',
      human_name_fr: 'Haut',
      human_name_en: 'High',
      type: 'Float',
    },
    {
      id: '0183417a-bbf6-71ea-9c44-a63bf7ffb433',
      human_name_fr: 'Bas',
      human_name_en: 'Low',
      type: 'Float',
    },
    {
      id: '0183417a-bccc-7388-9cad-dc1c57077a84',
      human_name_fr: 'Volume',
      human_name_en: 'Volume',
      type: 'Integer',
    },
    {
      id: '0183417a-bd9d-72c4-9a9b-927f5513d6b5',
      human_name_fr: 'Gain Ou Perte',
      human_name_en: 'Gain Or Loss',
      type: 'Enum',
      values_attributes: [
        {
          id: '0183417a-c483-714d-9765-700c17d4ac1e',
          human_name_fr: 'Gain',
          human_name_en: 'Gain',
        },
        {
          id: '0183417a-c599-7278-b800-4a6bdc188a7a',
          human_name_fr: 'Perte',
          human_name_en: 'Loss',
        },
      ],
      formula: %Q[if(open>close; "Loss"; "Gain")]
    },
    {
      id: '0183417a-be54-72d5-a4f0-9ad046fe7ffc',
      human_name_fr: 'Jour de la semaine',
      human_name_en: 'Day of week',
      type: 'Enum',
      values_attributes: [
        {
          id: '0183417d-6091-718e-bc5a-f637de817f3d',
          human_name_fr: 'Lundi',
          human_name_en: 'Monday',
        },
        {
          id: '0183417d-62b4-703c-af45-399971d4da0b',
          human_name_fr: 'Mardi',
          human_name_en: 'Tuesday',
        },
        {
          id: '0183417d-63b8-731c-a394-66de602003e8',
          human_name_fr: 'Mercredi',
          human_name_en: 'Wednesday',
        },
        {
          id: '0183417d-67e8-73ba-b99d-bf2b5bc1d8ca',
          human_name_fr: 'Jeudi',
          human_name_en: 'Thursday',
        },
        {
          id: '0183417d-6a29-739e-a4d6-26447ad21108',
          human_name_fr: 'Vendredi',
          human_name_en: 'Friday',
        },
        {
          id: '0183417d-6fb3-714a-9951-9556b374b5b2',
          human_name_fr: 'Samedi',
          human_name_en: 'Saturday',
        },
        {
          id: '0183417d-73ec-70a3-8ec9-e62f9fe9e8bd',
          human_name_fr: 'Dimanche',
          human_name_en: 'Sunday',
        },
      ],
    },
    {
      id: '0183417a-bfc5-736d-874d-f8e5245fe410',
      human_name_fr: 'Année',
      human_name_en: 'Year',
      type: 'Integer',
    },
    {
      id: '0183417a-c385-7246-bfd7-b9cae5bf22d8',
      human_name_fr: 'Trimestre',
      human_name_en: 'Quarter',
      type: 'Enum',
      values_attributes: [
        {
          id: '0183417e-a9f3-7255-b382-d48dfb13fa70',
          human_name_fr: 'Q1',
          human_name_en: 'Q1',
        },
        {
          id: '0183417e-af35-7344-b00a-1191d53072fa',
          human_name_fr: 'Q2',
          human_name_en: 'Q2',
        },
        {
          id: '0183417e-b129-7116-b474-0d45faf74ef5',
          human_name_fr: 'Q3',
          human_name_en: 'Q3',
        },
        {
          id: '0183417e-b2fd-7148-ba22-aa232fe73ac2',
          human_name_fr: 'Q4',
          human_name_en: 'Q4',
        },
      ],
    },
  ],

)

@schema.load

@dashboard = D::Uneek::R::Dashboard.where(name: 'Nasdaq').first
@dashboard ||= D::Uneek::R::Dashboard.create!(
  name: 'Nasdaq',
  human_name_fr: 'Nasdaq',
  human_name_en: 'Nasdaq',
  user_id: User.first.id,
  charts_attributes: [
    {
      human_name_fr: 'Gains et Pertes',
      human_name_en: 'Gain or Loss',
      type: 'Pie',
      width: 300,
      height: 300,
      render_label: true,
      render_legend: true,
      groups_attributes: [{
        source: 'attr',
        attr: 'gain_or_loss',
        value_type: 'string',
        agg: 'terms',
        axis: 'x',
      }],
      layouts: {"lg":{"w":2,"h":2,"x":0,"y":0},"md":{"w":3,"h":2,"x":0,"y":0},"sm":{"w":2,"h":2,"x":0,"y":0},"xs":{"w":2,"h":2,"x":0,"y":0}},
    },
    {
      human_name_fr: 'Trimestre',
      human_name_en: 'Quarter',
      type: 'Pie',
      inner_radius: 50,
      width: 300,
      height: 300,
      render_label: true,
      render_legend: true,
      groups_attributes: [{
        source: 'attr',
        attr: 'quarter',
        value_type: 'string',
        agg: 'terms',
        axis: 'x',
      }],
      layouts: {"lg":{"w":2,"h":2,"x":2,"y":0},"md":{"w":3,"h":2,"x":3,"y":0},"sm":{"w":2,"h":2,"x":2,"y":0},"xs":{"w":2,"h":2,"x":2,"y":0}},
    },
    {
      human_name_fr: 'Jour de la semaine',
      human_name_en: 'Day of week',
      type: 'Row',
      ordinal_colors: ['#3182bd', '#6baed6', '#9ecae1', '#c6dbef', '#dadaeb'],
      width: 300,
      height: 300,
      render_label: true,
      x_axis_ticks: 4,
      groups_attributes: [{
        source: 'attr',
        attr: 'day_of_week',
        value_type: 'string',
        agg: 'terms',
        axis: 'x',
      }],
      layouts: {"lg":{"w":2,"h":2,"x":4,"y":0},"md":{"w":4,"h":2,"x":6,"y":0},"sm":{"w":2,"h":2,"x":4,"y":0},"xs":{"w":2,"h":2,"x":0,"y":2}},
    },
    {
      human_name_fr: 'Fluctuation',
      human_name_en: 'Fluctuation',
      type: 'Bar',
      gap: 1,
      center_bar: true,
      width: 300,
      height: 300,
      margins_top: 10,
      margins_right: 50,
      margins_bottom: 30,
      margins_left: 40,
      groups_attributes: [{
        source: 'script',
        human_name_fr: 'Fluctuation',
        human_name_en: 'Fluctuation',
        # il faudrait calculer ce script à partir de la formule "round((close - open) / open * 100)"
        script: "Math.round((doc['close'].value - doc['open'].value) / doc['open'].value * 100)",
        value_type: 'number',
        agg: 'terms',
        min: '-10',
        max: '10',
        axis: 'x',
      }],
      layouts: {"lg":{"w":2,"h":2,"x":6,"y":0},"md":{"w":3,"h":2,"x":7,"y":2},"sm":{"w":2,"h":2,"x":4,"y":2},"xs":{"w":2,"h":2,"x":2,"y":2}},
    },
    {
      human_name_fr: 'Changements par mois',
      human_name_en: 'Changes per month',
      type: 'Line',
      width: 990,
      height: 250,
      render_area: true,
      elastic_y: true,
      render_legend: true,
      legend_x: 800,
      groups_attributes: [{
        source: 'attr',
        attr: 'date',
        value_type: 'date',
        agg: 'date_histogram',
        axis: 'x',
        calendar_interval: '1M',
      }, {
        source: 'script',
        human_name_fr: 'Valeur absolue des changements',
        human_name_en: 'Absolute change',
        script: "Math.abs(doc['close'].value - doc['open'].value)",
        agg: 'avg',
        value_type: 'number',
        axis: 'y',
      }],
      layouts: {"lg":{"w":4,"h":2,"x":8,"y":0},"md":{"w":7,"h":2,"x":0,"y":2},"sm":{"w":4,"h":2,"x":0,"y":2},"xs":{"w":4,"h":2,"x":0,"y":4}},
    },
    {
      human_name_fr: 'Nasdaq',
      human_name_en: 'Nasdaq',
      type: 'Table',
      layouts: {"lg":{"w":12,"h":4,"x":0,"y":2},"md":{"w":10,"h":4,"x":0,"y":4},"sm":{"w":6,"h":2,"x":0,"y":4},"xs":{"w":4,"h":5,"x":0,"y":6}},
    },
  ].map do |e|
    e.merge!({
      klass_name: "D::Uneek::Nasdaq",
      render_human_name: true,
    })
  end
)

@layout = @schema.layouts.where(klass_name: @Nasdaq.const_absolute_name, name: 'dashboard').with_action('index').first
unless @layout
  @layout = @schema.layouts.create!(
    klass_name: @Nasdaq.const_absolute_name, actions: ['index'],
    human_name_fr: 'Tableau de bord',
    human_name_en: 'Dashboard',
    name: 'dashboard',
    elements_attributes: [{
      component: 'Crm::Dashboard',
      component_params: {record_id: @dashboard.id},
      component_params_converter_type: 'Crm::Index::Base::ParamsConverter',
    }],
  )
end

unless D::Uneek::Nasdaq.count > 0

  download_ndx

  require 'csv'

  CSV.foreach("tmp/ndx.csv", headers: true) do |row|
    date = Date.strptime(row[0],'%m/%d/%Y')
    D::Uneek::Nasdaq.create({
      date: date,
      day_of_week: date.strftime('%A'),
      year: date.year,
      quarter: "Q#{(date.month/3.0).ceil}",
      open: row[1],
      high: row[2],
      low: row[3],
      close: row[4],
      volume: row[5],
    })

  end
end

puts "finished"
