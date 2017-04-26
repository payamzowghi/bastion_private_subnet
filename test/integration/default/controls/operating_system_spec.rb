control 'operating_system' do
  describe command('lsb_release -a') do
    its('stdout') { should match (/Ubuntu 16.04/) }
  
  services = [ 'cron', 'rsyslog' ]
  
  services.each do |service|
    describe service(service) do
      it { should be_enabled }  
      it { should be_running }
    end  
  end
end
