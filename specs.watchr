# Run me with:
#   $ watchr specs.watchr

# --------------------------------------------------
# Rules
# --------------------------------------------------
watch( '^spec.*/.*_spec\.rb'                 )  { |m| ruby  m[0] }
watch( '^lib(.*)/(.*?)\.rb'                  )  { |m| ruby "spec#{m[1]}/#{m[2]}_spec.rb" }
watch( '^spec/spec_helper\.rb'               )  { ruby specs }

watch( '^samples/(.*/)?(.*?)\.rb'            )  { |m| cuke "features/#{m[2]}.feature" }
watch( '^features/.*\.feature'               )  { |m| cuke m[0] }
watch( '^features/support/.*'                )  { |m| cuke features }
watch( '^features/step_definitions/.*'       )  { |m| cuke features }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
Signal.trap('QUIT') { ruby specs; cuke features  } # Ctrl-\
Signal.trap('INT' ) { abort("\n")                } # Ctrl-C

# --------------------------------------------------
# Helpers
# --------------------------------------------------
def ruby(*paths)
  run "ruby #{gem_opt} -I.:lib:spec -e'%w( #{paths.flatten.join(' ')} ).each {|p| require p }'"
end

def cuke(*paths)
  run "cucumber --format progress #{paths.flatten.join(' ')}"
end

def specs
  Dir['spec/**/*_spec.rb']
end

def features
  Dir['features/**/*.feature']
end

def run( cmd )
  puts   cmd
  system cmd
end

def gem_opt
  defined?(Gem) ? "-rubygems" : ""
end
