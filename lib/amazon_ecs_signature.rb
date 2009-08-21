# MODIFIED From Amazon's code. (http://docs.amazonwebservices.com/AmazonFPS/latest/FPSAccountManagementGuide/index.html?APPNDX_SignatureSampleCode.html)

  #  Copyright 2007 Amazon Technologies, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
  #  you may not use this file except in compliance with the License. You may obtain a copy of the License at:
  #
  #  http://aws.amazon.com/apache2.0
  #
  #  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  #  See the License for the specific language governing permissions and limitations under the License.
  
  require 'base64'
  require 'openssl'
  
  #  Please use ruby version 1.8.3 or later to run this sample.  
  #   1. Save this code in a file, PayNowWidgetUtils.rb.
  #  2. Run as: ruby PayNowWidgetUtils.rb
  #  3. You'll see a sample HTML form
  #  4. You can make a call to the 'generate_signed_form' subroutine as demonstrated at the end of this file.
  #  5. Change the parameters at the end of this file, to generate your own HTML Form
  #  6. This sample, by default, generates a form which points to the Pay Now Widget Sandbox. 
  #     In order to start pointing to Pay Now Widget Production, do the following: 
  #     Replace "authorize.payments-sandbox.amazon.com" with "authorize.payments.amazon.com" in the generated HTML
  #
  
  module AmazonSignature
    
    
  def sign_params(access_key, aws_secret_key, params)
      form_params['accessKey'] = access_key
      
      # lexicographically sort the form parameters in a case-insensitive way
      # and create the canonicalized string
      str_to_sign = ""
      params.keys.sort{|a,b| a.downcase <=> b.downcase}.each 
        {|k| str_to_sign += "#{k}#{params[k]}" }
  
      # calculate signature of the above string
      digest = OpenSSL::Digest::Digest.new('sha1')
      hmac = OpenSSL::HMAC.digest(digest, aws_secret_key, str_to_sign)
      form_params['signature'] = Base64.encode64(hmac).chomp
  
      return params
  end
  
  end
  
  include PayNowWidgetUtils
  ACCESS_KEY = 'put-your-access-key-here'
  SECRET_KEY = 'put-your-secret-key-here'
  print generate_signed_form(ACCESS_KEY, SECRET_KEY, 
         'amount' => 'USD 10.99', 
         'description' => 'Test Button', 
         'referenceId' => 'txn1102', 
         'returnUrl' => 'http://yourwebsite.com/return.html',
         'abandonUrl' => 'http://yourwebsite.com/abandon.html')
