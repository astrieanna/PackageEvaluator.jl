###############################################################################
# REQUIRE file (the one in the root directory of the package itself)
function checkREQUIRE(features, pkg_path)
  REQUIRE_path = joinpath(pkg_path, "REQUIRE")
  if isfile(REQUIRE_path)
    # Exists
    features[:REQUIRE_EXISTS] = true
    # Does it specifiy a Julia dependency?
    grep_result = readall(REQUIRE_path)
    features[:REQUIRE_VERSION] = ismatch(r"julia", grep_result)
  else
    # Does not exist
    features[:REQUIRE_EXISTS] = false
    features[:REQUIRE_VERSION] = false
  end
end

###############################################################################
# License file
function checkLicense(features, pkg_path)

  # Test for some sort of license file first
  possible_files = [joinpath(pkg_path, "LICENSE"),
                    joinpath(pkg_path, "LICENSE.md"),
                    joinpath(pkg_path, "README"),
                    joinpath(pkg_path, "README.md")]
  for filename in possible_files
    if isfile(filename)
      if guessLicense(features, filename)
        return
      end
    end
  end      
    
  # Failed
  features[:LICENSE_EXISTS] = false
  features[:LICENSE] = "Unknown"
  features[:LICENSE_FILE] = ""
end

function guessLicense(features, filename)
  # Be greedy, read the whole file
  # TODO: Make [key: license, value: list of possibilities] pairs, loop
  # println("Looking in $filename for license...")
  text = lowercase(readall(filename))
  if ismatch(r"mit license", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "MIT"
  elseif ismatch(r"gpl version 2", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "GPL v2"
  elseif ismatch(r"gpl version 3", text) ||
         ismatch(r"http://www.gnu.org/licenses/gpl-3.0.txt", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "GPL v3"
  else
    return false
  end
  features[:LICENSE_FILE] = filename
  return true
end


###############################################################################
# Testing folder/file
function checkTesting(features, pkg_path)
  # Look for runtests.jl
  possible_locations = [
    joinpath(pkg_path, "test", "runtests.jl"),
    joinpath(pkg_path, "test", "run_tests.jl"),
    joinpath(pkg_path, "run_tests.jl"),
    joinpath(pkg_path, "runtests.jl")]
  foundit = 0
  for i = 1:length(possible_locations)
    if isfile(possible_locations[i])
      foundit = i
      break
    end
  end
  features[:TEST_EXISTS] = (foundit>0)
  features[:TEST_RUNTESTS] = (foundit==1)
  
  # Second, do they have a .travis.yml file?
  travis_file = joinpath(pkg_path, ".travis.yml")
  features[:TEST_TRAVIS] = isfile(travis_file)

  # Run the tests to see how they go
  if features[:TEST_EXISTS]
    features[:TEST_PASSES] = true
    testoutput = ""
    try
      testoutput = readall(`julia $(possible_locations[foundit])`)
    catch
      features[:TEST_PASSES] = false
    end
    println("00")
    println(testoutput)
    println("00")
    features[:TEST_NOWARNING] = !ismatch(r"WARNING", testoutput)
  end
end
