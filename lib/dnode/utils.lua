local function copy_table(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = v
  end
  return copy
end

return {
	copy_table = copy_table
}
