module Genome
  module Importers
    module Chembl

      def self.source_info
        {
          site_url: 'https://www.ebi.ac.uk/chembl',
          base_url: 'https://www.ebi.ac.uk/chembldb/index.php/target/inspect/',
          citation: "The ChEMBL bioactivity database: an update. Bento AP, Gaulton A, Hersey A, Bellis LJ, Chambers J, Davies M, Kruger FA, Light Y, Mak L, McGlinchey S, Nowotka M, Papadatos G, Santos R, Overington JP. Nucleic Acids Res. 42(Database issue):D1083-90. PubMed ID: 24214965",
          source_db_version: 'chembl_20',
          source_type_id: DataModel::SourceType.INTERACTION,
          source_db_name: 'ChEMBL',
          full_name: 'The ChEMBL Bioactivity Database',
          source_trust_level_id: DataModel::SourceTrustLevel.EXPERT_CURATED
        }
      end

      def self.run(tsv_path)
        blank_filter = ->(x) { x.blank? || x == "''" || x == '""' }
        upcase = ->(x) {x.upcase}
        downcase = ->(x) {x.downcase}
        known = ->() {if :action_type.blank?
                        'unknown'
                      else
                        'known'
                      end
        }
        TSVImporter.import tsv_path, ChemblRow, source_info do
          interaction known_action_type: known, transform: downcase do
            drug :drug_chembl_id, nomenclature: 'ChEMBL Drug Identifier', primary_name: :drug_name, transform: upcase do
              name :drug_name, nomenclature: 'ChEMBL Drug Name', transform: upcase
            end
            gene :gene_chembl_id, nomenclature: 'ChEMBL Gene Identifier' do
              names :gene_symbol, nomenclature: 'ChEMBL Gene Symbol', unless: blank_filter
              names :uniprot_id, nomenclature: 'UniProt Accession', unless: blank_filter
              names :uniprot_name, nomenclature: 'UniProt Name', unless: blank_filter
              # target_ligand fields are ignored for now.
            end
            attribute :mechanism_of_action, name: 'Mechanism of Interaction', transform: downcase, unless: blank_filter
            attribute :direct_interaction, name: 'Direct Interaction', unless: blank_filter
            attributes :fda, name: 'FDA ID', unless: blank_filter
            attributes :pmid, name: 'PMID', unless: blank_filter
            attribute :action_type, name: 'Interaction Type', transform: downcase, unless: blank_filter
          end
        end.save!
      end
    end
  end
end