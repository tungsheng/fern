-- Example file for testing nvim-cursor
-- Try selecting code and using:
--   <leader>ae - Explain this code
--   <leader>ad - Generate documentation
--   <leader>ar - Suggest refactoring
--   <leader>af - Find and fix bugs

-- Simple function to test with
local function calculate_factorial(n)
  if n < 0 then
    return nil
  end
  if n == 0 or n == 1 then
    return 1
  end
  local result = 1
  for i = 2, n do
    result = result * i
  end
  return result
end

-- Function with potential bug
local function process_data(data)
  local results = {}
  for i = 1, #data do
    if data[i] > 0 then
      results[i] = data[i] * 2
    end
  end
  return results
end

-- Complex function that could use refactoring
local function validate_user_input(input)
  if not input then return false end
  if type(input) ~= "table" then return false end
  if not input.name then return false end
  if not input.email then return false end
  if not input.email:match("^[%w._%+-]+@[%w.-]+%.%w+$") then return false end
  if not input.age then return false end
  if type(input.age) ~= "number" then return false end
  if input.age < 0 or input.age > 150 then return false end
  return true
end

-- Class-like table for testing documentation generation
local User = {}
User.__index = User

function User:new(name, email, age)
  local instance = setmetatable({}, User)
  instance.name = name
  instance.email = email
  instance.age = age
  instance.created_at = os.time()
  return instance
end

function User:is_adult()
  return self.age >= 18
end

function User:get_display_name()
  return string.format("%s (%d years old)", self.name, self.age)
end

-- Test the manual test script
print("Example file loaded. Try these actions:")
print("1. Select calculate_factorial and press <leader>ae")
print("2. Select User:new and press <leader>ad")
print("3. Select validate_user_input and press <leader>ar")
print("4. Select process_data and press <leader>af")
print("5. Press <leader>aE to explain the entire buffer")
print("6. Press <leader>ac for a custom prompt")

return {
  User = User,
  calculate_factorial = calculate_factorial,
  process_data = process_data,
  validate_user_input = validate_user_input
}
