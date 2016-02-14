namespace :dgidb do
  namespace :update do
    desc 'update CIViC'
    task civic: :environment do
      civic = Genome::Updaters::GetCivic.new()
      if civic.is_current?
        puts('is current')
      else
        civic.to_tsv
        if DataModel::Source.where('lower(sources.source_db_name) = ?', 'civic').any?
          Utils::Database.delete_source('CIViC')
        end
        Genome::Importers::Civic.run(civic.default_savefile, civic.new_version)
      end
    end

    desc 'update DoCM'
    task docm: :environment do
      docm = Genome::Updaters::GetDocm.new()
      if docm.is_current?
        puts('is current')
      else
        docm.to_tsv
        if DataModel::Source.where('lower(sources.source_db_name) = ?', 'docm').any?
          Utils::Database.delete_source('DoCM')
        end
        Genome::Importers::Docm.run(docm.default_savefile, docm.new_version)
      end
    end

    desc 'update GO'
    task go: :environment do
      Rake::Task['dgidb:import:go']
    end

    desc 'update DrugBank'
    task go: :environment do
      Rake::Task['dgidb:import:drugbank']
    end

    desc 'update Entrez'
    task entrez: :environment do
      #TODO: Port updater code
      if DataModel::Source.where('lower(sources.source_db_name) = ?', 'entrez').any?
        Utils::Database.delete_source('Entrez')
      end
      f = File.join(Rails.root, 'lib/genome/updaters/data/entrez_genes.tsv')
      Genome::Importers::Entrez.run(f)
    end

    desc 'update PubChem'
    task pubchem: :environment do
      # Unlike other importers, PubChem deletes records as part of updater
      Genome::Updaters::GetPubchem.run!
    end

    desc 'update all'
    task all: :environment do
      # Code for doing various updates
      # Entrez first
      puts 'Updating Entrez...'
      Rake::Task['dgidb:update:entrez'].execute

      # Other sources
      puts 'Updating CIViC...'
      Rake::Task['dgidb:update:civic'].execute
      puts 'Updating DoCM...'
      Rake::Task['dgidb:update:docm'].execute

      # PubChem last
      puts 'Updating PubChem...'
      Rake::Task['dgidb:update:pubchem'].execute

      # Cleanup
      puts 'Grouping Genes...'
      Genome::Groupers::GeneGrouper.run
      puts 'Importing Pathways...'
      pathway_file = File.join(Rails.root, 'lib/genome/updaters/data/interactions.human')
      Genome::Importers::Entrez::EntrezGenePathwayImporter.new(pathway_file).import!
      puts 'Grouping Drugs...'
      Genome::Groupers::DrugGrouper.run
      puts 'Removing Common Aliases...'
      Utils::Database.destroy_common_aliases
      puts 'Populating source counters...'
      Genome::Normalizers::PopulateCounters.populate_source_counters
      puts 'Attempting to normalize drug types...'
      Genome::Normalizers::DrugTypeNormalizers.normalize_types
      puts 'Filling in source trust levels...'
      Genome::Normalizers::SourceTrustLevel.populate_trust_levels
      puts 'Attempting to normalize interaction types...'
      Genome::Normalizers::InteractionClaimType.normalize_types
      puts 'Exporting Categories...'
      Utils::TSV.generate_categories_tsv
      puts 'Exporting Interactions...'
      Utils::TSV.generate_interactions_tsv
      puts 'Clearing cache...'
      Rails.cache.clear
    end

    # desc 'generate a complete druggable categories tsv file'
    # task categories_tsv: :environment do
    #   Utils::TSV.generate_categories_tsv
    # end
  end
end