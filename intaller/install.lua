local rdir = '/.mitrepack'

if not fs.isDir('/.mitrepack') then
    print('Initializing Mitrepack files...')
    fs.makeDir(rdir)
end

shell.run('pastebin', 'run', '')

print('Mitrepack successfully installed !')
