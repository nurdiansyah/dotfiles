local M = {}

-- Simple project profile detector
function M.detect()
  -- Java projects
  if vim.fn.filereadable("pom.xml") == 1 or vim.fn.filereadable("build.gradle") == 1 or vim.fn.filereadable("build.gradle.kts") == 1 then
    return "java"
  end

  -- Node.js projects
  if vim.fn.filereadable("package.json") == 1 then
    return "javascript"
  end

  -- DevOps / k8s / Helm patterns
  if vim.fn.isdirectory("charts") == 1 or vim.fn.filereadable("kustomization.yaml") == 1 then
    return "devops"
  end

  return "auto"
end

return M
