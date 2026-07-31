storage web:
    provider="http",


rule find_sums:
    input:
        script_path=storage.web(
            "https://raw.githubusercontent.com/langmead-lab/recount-unify/26632ed655ceee542339d9385f0d4580f0f9f793/scripts/find_new_files.sh"
        ),
        input_dir="results/{sample}",
        sample_ids_file="",
    output:
        "unify/{type}.exon_bw_count.groups.manifest",
    params:
        
    
        
