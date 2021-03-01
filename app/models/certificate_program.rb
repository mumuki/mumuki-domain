class CertificateProgram < ApplicationRecord
  belongs_to :organization
  has_many :certificates

  def friendly
    title
  end

  def template_html_erb
    self[:template_html_erb] ||= <<HTML
<style>
  .qr-code {
    bottom: 5px;
    right: 5px;
    height: 15mm;
    width: 15mm;
  }
  .name {
    position: absolute;
    width: 100%;
    top: 380px;
    text-align: center;
  }
</style>
<!-- You can use interpolations like --
  <%#= certificate.start_date %>
  <%#= certificate.end_date %>
  <%#= user.formal_first_name %>
  <%#= user.formal_last_name %>
  <%#= user.formal_full_name %>
  <%#= certificate_program.title %>
  <%#= certificate_program.description %>
  <%#= organization.name %>
  <%#= organization.display_name %>
--                                  -->
<section class="name">
    <h1><%= user.formal_full_name %></h1>
</section>
HTML
  end

end
