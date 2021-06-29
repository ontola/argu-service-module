# frozen_string_literal: true

require 'rdf'
require 'rdf/vocab'

class NS < LinkedRails::Vocab
  register_strict(org)
  register(:argu, 'https://argu.co/ns/core#')
  register(:mapping, 'https://argu.co/voc/mapping/')
  register(:meeting, 'https://argu.co/ns/meeting/')
  register(:meta, 'https://argu.co/ns/meta#')
  register(:ori, 'https://id.openraadsinformatie.nl/')
  register(:rivm, 'https://argu.co/ns/rivm#')
  register(:bio, 'http://purl.org/vocab/bio/0.1/')
  register(:cube, 'http://purl.org/linked-data/cube#')
  register(:dbo, 'http://dbpedia.org/ontology/')
  register(:dbpedia, 'http://dbpedia.org/resource/')
  register(:hydra, 'http://www.w3.org/ns/hydra/core#')
  register(:ncal, 'http://www.semanticdesktop.org/ontologies/2007/04/02/ncal#')
  register(:opengov, 'http://www.w3.org/ns/opengov#')
  register(:p, 'http://www.wikidata.org/prop/')
  register(:pav, 'http://purl.org/pav/')
  register(:person, 'http://www.w3.org/ns/person#')
  register(:time, 'http://www.w3.org/2006/time#')
  register(:wdata, 'https://www.wikidata.org/wiki/Special:EntityData/')
  register(:wd, 'http://www.wikidata.org/entity/')
  register(:wds, 'http://www.wikidata.org/entity/statement/')
  register(:wdref, 'http://www.wikidata.org/reference/')
  register(:wdv, 'http://www.wikidata.org/value/')
  register(:wdt, 'http://www.wikidata.org/prop/direct/')
  register(:xmlns, 'http://www.w3.org/2000/xmlns/')
end
