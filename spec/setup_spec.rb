require 'spec_helper'

describe 'metroextractor::setup' do
  let(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.automatic[:memory][:total] = '2048kB'
    end.converge(described_recipe)
  end

  before do
    stub_command('pgrep postgres').and_return(true)
    stub_command('test -f /var/lib/postgresql/9.3/main/PG_VERSION').and_return(true)
    stub_command("psql -c \"SELECT rolname FROM pg_roles WHERE rolname='osmuser'\" | grep osmuser").and_return(true)
    stub_command("psql -c \"SELECT datname from pg_database WHERE datname='osm'\" | grep osm").and_return(true)
    stub_command("psql -c 'SELECT lanname FROM pg_catalog.pg_language' osm | grep '^ plpgsql$'").and_return(true)
    stub_command("psql -c \"SELECT rolname FROM pg_roles WHERE rolname='osm'\" | grep osm").and_return(true)
  end

  %w(
    osm2pgsql::default
    osmosis::default
  ).each do |r|
    it "should include the #{r} recipe" do
      chef_run.should include_recipe r
    end
  end

  %w(
    gdal-bin
    imposm
    zip
  ).each do |p|
    it 'should install gdal-bin' do
      chef_run.should install_package p
    end
  end

  it 'should create the directory /opt/metroextractor-scripts' do
    chef_run.should create_directory '/opt/metroextractor-scripts'
  end

  it 'should create file /opt/metroextractor-scripts/cities.json' do
    chef_run.should create_cookbook_file('/opt/metroextractor-scripts/cities.json').with(
      owner:  'metro',
      source: 'cities.json'
    )
  end

  it 'should create template /opt/metroextractor-scripts/osmosis.sh' do
    chef_run.should create_template('/opt/metroextractor-scripts/osmosis.sh').with(
      owner:  'metro',
      mode:   0755,
      source: 'osmosis.sh.erb'
    )
  end

  it 'should create template /opt/metroextractor-scripts/osm2pgsql.sh' do
    chef_run.should create_template('/opt/metroextractor-scripts/osm2pgsql.sh').with(
      owner:  'metro',
      mode:   0755,
      source: 'osm2pgsql.sh.erb'
    )
  end

  it 'should create the file /opt/metroextractor-scripts/osm2pgsql.style' do
    chef_run.should create_cookbook_file('/opt/metroextractor-scripts/osm2pgsql.style').with(
      owner:  'metro',
      source: 'osm2pgsql.style'
    )
  end

  it 'should create /mnt/metro/ex' do
    chef_run.should create_directory '/mnt/metro/ex'
  end

  it 'should create /mnt/metro/logs' do
    chef_run.should create_directory '/mnt/metro/logs'
  end

  it 'should create /mnt/metro/shp' do
    chef_run.should create_directory '/mnt/metro/shp'
  end
end
