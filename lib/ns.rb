# frozen_string_literal: true

require 'rdf'

module NS
  ARGU = RDF::Vocabulary.new('https://argu.co/ns/core#')
  MAPPING = RDF::Vocabulary.new('https://argu.co/voc/mapping/')
  MEETING = RDF::Vocabulary.new('https://argu.co/ns/meeting/')
  META = RDF::Vocabulary.new('https://argu.co/ns/meta#')
  ONTOLA = RDF::Vocabulary.new('https://ns.ontola.io/')
  ORI = RDF::Vocabulary.new('https://id.openraadsinformatie.nl/')
  RIVM = RDF::Vocabulary.new('https://argu.co/ns/rivm#')

  AS = RDF::Vocabulary.new('https://www.w3.org/ns/activitystreams#')
  BIBFRAME = RDF::Vocabulary.new('http://bibframe.org/vocab/')
  BIBO = RDF::Vocabulary.new('http://purl.org/ontology/bibo/')
  BIO = RDF::Vocabulary.new('http://purl.org/vocab/bio/0.1/')
  CC = RDF::Vocabulary.new('http://creativecommons.org/ns#')
  CUBE = RDF::Vocabulary.new('http://purl.org/linked-data/cube#')
  DBO = RDF::Vocabulary.new('http://dbpedia.org/ontology/')
  DC = RDF::Vocabulary.new('http://purl.org/dc/terms/')
  DBPEDIA = RDF::Vocabulary.new('http://dbpedia.org/resource/')
  FHIR = RDF::Vocabulary.new('http://hl7.org/fhir/')
  FOAF = RDF::Vocabulary.new('http://xmlns.com/foaf/0.1/')
  GEO = RDF::Vocabulary.new('http://www.w3.org/2003/01/geo/wgs84_pos#')
  HTTP = RDF::Vocabulary.new('http://www.w3.org/2011/http#')
  HYDRA = RDF::Vocabulary.new('http://www.w3.org/ns/hydra/core#')
  LL = RDF::Vocabulary.new('http://purl.org/link-lib/')
  NCAL = RDF::Vocabulary.new('http://www.semanticdesktop.org/ontologies/2007/04/02/ncal#')
  OPENGOV = RDF::Vocabulary.new('http://www.w3.org/ns/opengov#')
  ORG = RDF::Vocabulary.new('http://www.w3.org/ns/org#')
  P = RDF::Vocabulary.new('http://www.wikidata.org/prop/')
  PAV = RDF::Vocabulary.new('http://purl.org/pav/')
  PERSON = RDF::Vocabulary.new('http://www.w3.org/ns/person#')
  PROV = RDF::Vocabulary.new('http://www.w3.org/ns/prov#')
  SCHEMA = RDF::Vocabulary.new('http://schema.org/')
  SH = RDF::Vocabulary.new('http://www.w3.org/ns/shacl#')
  SKOS = RDF::Vocabulary.new('http://www.w3.org/2004/02/skos/core#')
  TIME = RDF::Vocabulary.new('http://www.w3.org/2006/time#')
  WDATA = RDF::Vocabulary.new('https://www.wikidata.org/wiki/Special:EntityData/')
  WD = RDF::Vocabulary.new('http://www.wikidata.org/entity/')
  WDS = RDF::Vocabulary.new('http://www.wikidata.org/entity/statement/')
  WDREF = RDF::Vocabulary.new('http://www.wikidata.org/reference/')
  WDV = RDF::Vocabulary.new('http://www.wikidata.org/value/')
  WDT = RDF::Vocabulary.new('http://www.wikidata.org/prop/direct/')
  XMLNS = RDF::Vocabulary.new('http://www.w3.org/2000/xmlns/')

  OWL = RDF::OWL
  RDFS = RDF::RDFS
  RDFV = RDF::RDFV
  XSD = RDF::XSD
end
