#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

@schema = Dynamic::Schema.where(name: 'Cd83').first

if @schema.nil?
  ::UneekSsoClient.sync_all!
  @schema = ::Dynamic::Schema.where(name: 'Cd83').first
end

@schema.load

require 'faker'
require File.expand_path('../lib/download_images', __dir__)
require 'progress_bar'

Faker::Config.locale = 'fr'

download_logos
download_avatars

def fake_emails_attributes
  [
    {
      address: Faker::Internet.email,
      tag: 'Home',
    }
  ]
end

@count = ARGV[0] ? ARGV[0].to_i : 200

puts "create authors" # ----------------------------------------------------------

@participants_count = @count

bar = ProgressBar.new(@participants_count)

::ModelDependency.with_dependencies_computed_later do

  @participants_count.times do

    gender = rand(0..1) == 0 ? 'Female' : 'Male'

    D::Cd83::Contact.create!(
      first_name: Faker::Name.send("#{gender.underscore}_first_name"),
      last_name: Faker::Name.last_name,
      pseudo: rand(0..1) == 0 ? Faker::Superhero.name : nil,
      civility: gender == 'Male' ? 'Mr.' : 'Mrs.',
      photo: fake_avatar,
    )

    bar.increment!
  end

end

puts "create maison_d_editions" # ----------------------------------------------------------

@maison_d_editions_count = @count

bar = ProgressBar.new(@maison_d_editions_count)

::ModelDependency.with_dependencies_computed_later do

  @maison_d_editions_count.times do
    D::Cd83::Account.create!(
      name: Faker::Book.publisher,
      logo: fake_logo,
    )
    bar.increment!
  end

end

puts "create prix_litteraires" # ----------------------------------------------------------

@prix_litteraires_count = @count

bar = ProgressBar.new(@prix_litteraires_count)

::ModelDependency.with_dependencies_computed_later do

  i = 0
  @prix_litteraires_count.times do
    D::Cd83::PrixLitteraire.create!(
      libelle_prix: "Prix #{i}"
    )
    bar.increment!
    i += 1
  end

end

puts "create ouvrages" # ----------------------------------------------------------

@ouvrages_count = @count

bar = ProgressBar.new(@ouvrages_count)

::ModelDependency.with_dependencies_computed_later do

  authors = D::Cd83::Contact.all

  i = 0
  @ouvrages_count.times do
    D::Cd83::Ouvrage.create!(
      titre: Faker::Book.title,
      auteur_1: [authors[i]],
      maison_d_edition: [D::Cd83::Account.limit(1).order("RANDOM()").first],
      prix_litteraires_1: D::Cd83::PrixLitteraire.limit(1).order("RANDOM()").first, # why belongs_to ?
      # :referent_maison_edition,
      # :participation_10,
      # :notes,
      # :annee_de_publication,
      # :couverture_attachments,
      # :presentation_ouvrage_attachments,
    )
    bar.increment!
    i += 1
  end

end

puts "create periode_journees" # ----------------------------------------------------------

D::Cd83::PeriodeJournee.create!(valeur: 'Journée')
D::Cd83::PeriodeJournee.create!(valeur: 'Matin')
D::Cd83::PeriodeJournee.create!(valeur: 'Après-midi')

puts "create lieux" # ----------------------------------------------------------

D::Cd83::Lieux.create!(nom: 'lieu 1')
D::Cd83::Lieux.create!(nom: 'lieu 2')
D::Cd83::Lieux.create!(nom: 'lieu 3')

puts "create domaines" # ----------------------------------------------------------

D::Cd83::Domaine.create!(value: 'Auteur')
D::Cd83::Domaine.create!(value: 'Autre')

puts "create domaines macro" # ----------------------------------------------------------

D::Cd83::DomaineMacro.create!(valeur: 'Auteur')

puts "create manifestations" # ----------------------------------------------------------

D::Cd83::Manifestation.create!(
  nom: "manifestation #{DateTime.now.year}",
  libelle: "manifestation #{DateTime.now.year}",
  debut: DateTime.now,
  fin: DateTime.now + 1.day,
  pour_diffusion_sur_site_internet: true,
)

puts "create categorie_litteraires" # ----------------------------------------------------------

D::Cd83::CategorieLitteraire.create!(categorie: 'Généraliste')
D::Cd83::CategorieLitteraire.create!(categorie: 'BD')
D::Cd83::CategorieLitteraire.create!(categorie: 'Jeunesse')

puts "create participations" # ----------------------------------------------------------
@participations_count = @count

bar = ProgressBar.new(@participations_count)

participants = D::Cd83::Contact.all
ouvrages = D::Cd83::Ouvrage.all

::ModelDependency.with_dependencies_computed_later do
  i = 0
  @participations_count.times do
    D::Cd83::Participation.create!(
      participant: participants[i],
      evenement: D::Cd83::Manifestation.last,
      ouvrage_2: ouvrages[i],
      lieux: D::Cd83::Lieux.limit(1).order("RANDOM()").first, # why lieux with x ?
      jour_de_presence_1: D::Cd83::PeriodeJournee.limit(1).order("RANDOM()").first,
      jour_de_presence_2: D::Cd83::PeriodeJournee.limit(1).order("RANDOM()").first,
      jour_de_presence_3: D::Cd83::PeriodeJournee.limit(1).order("RANDOM()").first,
      categorie_litteraire: D::Cd83::CategorieLitteraire.limit(1).order("RANDOM()").first,
      domaine: [D::Cd83::Domaine.where(value: 'Auteur').first, D::Cd83::Domaine.where(value: 'Autre').first],
      domaine_macro: D::Cd83::DomaineMacro.where(valeur: 'Auteur').first,
      # :hebergement,
      # :suivi_presence_1,
      # :programmations,
      # :transport_scolaire_1,
      # :groupe_scolaire_5,
      # :transport,
      # :accompagnants,
      # :maison_d_edition_2,
      # :addresses,
      # :exposant_1,
      # :responsable_exposant,
      # :address_contact,
      # :non_disponibilites,
      # :biographie_1_attachments,
      # :attachments_attachments,
      # :fdr_logistique_attachment,
      # :fdr_auteur_complete_attachment,
      # :fdr_bouquiniste_attachment,
      # :fdr_institutionnel_attachment,
      # :fdr_libraire_attachment,
      # :fdr_presse_attachment,
      # :fdr_scolaire_attachment,
      # :badge_exposant_attachment,
      # :cartel_auteur_attachment,
      # :fdr_exposant_attachment,
    )
    bar.increment!
    i += 1
  end

end


puts "create programmations" # ----------------------------------------------------------

bar = ProgressBar.new(@participations_count)
participations = D::Cd83::Participation.all
::ModelDependency.with_dependencies_computed_later do
  i = 0
  @participations_count.times do # assume one intervention by participation
    D::Cd83::Programmation.create!(
      participant: [participations[i]], # participant is a participation :(
      debut: DateTime.now,
      fin: DateTime.now + 1.hour,
      manifestation_id: D::Cd83::Manifestation.first.id,
    )
    bar.increment!
    i += 1
  end
end

ModelDependency::GroupingWorker.new.perform

puts "finished"

# for clear data:
# [D::Cd83::Contact, D::Cd83::Account, D::Cd83::PrixLitteraire, D::Cd83::Manifestation, D::Cd83::Participation, D::Cd83::Ouvrage, D::Cd83::Lieux, D::Cd83::PeriodeJournee].map(&:destroy_all)
