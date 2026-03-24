#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'shellwords'

# Uso:
#   ruby scripts/delete-gitlab-user.rb "Administrador Zenfocus"
#   CONTAINER_NAME=meu-gitlab ruby scripts/delete-gitlab-user.rb "usuario" --hard-delete

if ARGV.empty?
  warn "Uso: ruby scripts/delete-gitlab-user.rb \"NOME_OU_USERNAME\" [--hard-delete]"
  exit 1
end

query = ARGV[0].to_s.strip
hard_delete = ARGV.include?('--hard-delete')
container = ENV.fetch('CONTAINER_NAME', 'zenfocus-gitlab')

if query.empty?
  warn 'Erro: informe o nome/username do usuário.'
  exit 1
end

rails_code = <<~RUBY
  query = #{query.dump}
  hard_delete = #{hard_delete}

  admin = User.where(admin: true).order(:id).first
  if admin.nil?
    puts 'ERRO: nenhum admin encontrado para executar a operacao.'
    exit 1
  end

  # Busca por username exato, nome exato e email exato.
  user = User.find_by(username: query) || User.find_by(name: query) || User.find_by(email: query)

  if user.nil?
    puts "ERRO: usuario nao encontrado para '\#{query}'."
    exit 1
  end

  if user.username == 'root'
    puts 'ERRO: remocao do root bloqueada por seguranca.'
    exit 1
  end

  begin
    # Tenta assinatura mais comum do service object em versoes recentes.
    service = ::Users::DestroyService.new(admin, hard_delete: hard_delete)
    result = service.execute(user)

    success = if result.respond_to?(:success?)
                result.success?
              elsif result.is_a?(Hash) && result.key?(:status)
                result[:status] == :success
              else
                !!result
              end

    if success
      mode = hard_delete ? 'com contribuicoes removidas' : 'mantendo contribuicoes (ghost user)'
      puts "OK: usuario '\#{user.username}' removido (\#{mode})."
      exit 0
    end

    message = if result.respond_to?(:message)
                result.message
              elsif result.is_a?(Hash)
                result[:message] || result[:error]
              end

    puts "ERRO: falha ao remover usuario '\#{user.username}'. \#{message}".strip
    exit 1
  rescue ArgumentError
    # Fallback para possiveis assinaturas de versoes diferentes.
    begin
      service = ::Users::DestroyService.new(admin)
      result = service.execute(user, hard_delete: hard_delete)

      success = if result.respond_to?(:success?)
                  result.success?
                elsif result.is_a?(Hash) && result.key?(:status)
                  result[:status] == :success
                else
                  !!result
                end

      if success
        mode = hard_delete ? 'com contribuicoes removidas' : 'mantendo contribuicoes (ghost user)'
        puts "OK: usuario '\#{user.username}' removido (\#{mode})."
        exit 0
      end

      message = if result.respond_to?(:message)
                  result.message
                elsif result.is_a?(Hash)
                  result[:message] || result[:error]
                end

      puts "ERRO: falha ao remover usuario '\#{user.username}'. \#{message}".strip
      exit 1
    rescue => e
      puts "ERRO: excecao ao remover usuario: \#{e.class} - \#{e.message}"
      exit 1
    end
  rescue => e
    puts "ERRO: excecao ao remover usuario: \#{e.class} - \#{e.message}"
    exit 1
  end
RUBY

cmd = ['docker', 'exec', '-i', container, 'gitlab-rails', 'runner', rails_code]
stdout, stderr, status = Open3.capture3(*cmd)

print stdout unless stdout.empty?
warn stderr unless stderr.empty?

exit status.exitstatus || 1
