SPECIES=[ x.strip() for x in open('SPECIES-LIST-k21.txt.rm') ]
BW_ROCKSDB='/group/ctbrowngrp5/sra-metagenomes/20241128-k21-s1000'

rule all:
    input:
        expand('queries/{s}.k21.sig.zip', s=SPECIES),
        expand("outputs.branchwater/csv/{s}.csv", s=SPECIES),
        expand("outputs.branchwater/csv+pvals/{s}.parquet", s=SPECIES),


rule get_query:
    input:
        '/home/ctbrown/scratch3/2026-gtdb-dl/gtdb-cds-rs226.species.singleton.sig.zip'
    output:
        'queries/{s}.k21.sig.zip',
    shell: '''
        sourmash sig grep {wildcards.s:q} {input:q} -o {output:q}
    '''

rule search_species:
    input:
        q='queries/{species}.k21.sig.zip',
        db=BW_ROCKSDB,
    output:
        "outputs.branchwater/csv/{species}.csv",
    threads: 1
    shell: """
        sourmash scripts manysearch -c 1 -t 0 -k 21 -s 1000 \
            {input.q:q} {input.db:q} -o {output:q}
    """

rule add_pvals:
    input:
        csv="outputs.branchwater/csv/{species}.csv",
        metag_mf="wort-703k.mf.csv",
        query="queries/{species}.k21.sig.zip",
    output:
        "outputs.branchwater/csv+pvals/{species}.parquet",
    threads: 1
    shell: """
        ../2026-pancoding-core/scripts/add-pvals-to-manysearch.py \
            {input.csv:q} --queries {input.query:q} --against {input.metag_mf:q} \
            -P {output:q} --remove-missing
    """

