module ACME
  def self.sign
    system('acme_tiny.py --account-key /root/account.key --csr /root/domain.csr --acme-dir /var/www/challenges/ --ca https://acme-staging.api.letsencrypt.org > /root/signed.crt')
  end
end
