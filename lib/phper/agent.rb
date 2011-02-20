#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'phper'
class Phper::Agent
  include Phper

  def initialize
    @login = false
  end

  def log dest
    RestClient.log = dest
  end
  
  def login(u,p)
    @auth = {:user => u, :password => p}
    begin
      projects
      @login = true
    rescue => e
      puts e
      @login = false
    end
  end

  def login?
    @login
  end

  def projects id = nil
    if id
      get("/projects/%s" % id)
    else
      get("/projects")
    end
  end

  def projects_create name
    param = {}
    param[:name] = name if name
    post("/projects",{:project => param})
  end

  def keys
    get("/keys")
  end

  def keys_create key
    param = {}
    param[:public_key] = key if key
    post("/keys",{:key => param})
  end

  def keys_delete name
    count = 0
    keys.each { |key|
      if name == name_of_key(key["key"]["public_key"])
        delete("/keys/%i" % key["key"]["id"])
        count += 1
      end
    }
    count
  end

  def keys_delete_all
    count = 0
    keys.each { |key|
      delete("/keys/%i" % key["key"]["id"])
      count += 1
    }
    count
  end

  def servers project
    get("/projects/%s/servers" % project)
  end

  def servers_create project,param
    defaults = get("/projects/%s/servers/new" % project)["server"]
    param[:name] = defaults["name"] unless param.has_key?(:name)
    param[:fqdn] = defaults["fqdn"] unless param.has_key?(:fqdn)
    post("/projects/%s/servers" % project ,{:server => param})
  end


  def servers_delete project,name
    count = 0;
    servers(project).each { |s|
      if s["server"]["fqdn"] == name or s["server"]["name"] == name
        delete("/projects/%s/servers/%s"%[project,s["server"]["id"]])
        count += 1
      end
    }
    count
  end






  def post(url,data = {},format=:json)
    call(:post,url,data,format)
  end

  def get(url,data = {},format=:json)
    call(:get,url,data,format)
  end

  def put(url,data = {},format=:json)
    call(:put,url,data,format)
  end

  def delete(url,data = {},format=:json)
    call(:delete,url,data,format)
  end

  def base_url
    ENV["PHPERJP_URL"] || "https://phper.jp"
  end

  protected
  def call(method,url,data,format)
    url = "%s%s.%s" % [base_url,url,format.to_s]
    resource = RestClient::Resource.new(url,:user => @auth[:user], :password => @auth[:password])
    parse(resource.send(method.to_s,data),format)
  end

  def parse(data,format)
    return "" if data.length == 0
    if format == :json
      data = "{}" if data.length < 2
      return JSON.parse(data)
    end
    raise format + "is not support formats."
  end

end