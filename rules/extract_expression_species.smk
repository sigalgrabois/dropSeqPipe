"""Extract expression fof mixed species"""

#Which rules will be run on the host computer and not sent to nodes
localrules: plot_rna_metrics_species, merge_umi_species, merge_counts_species

rule extract_umi_expression_species:
	input:
		data='data/{sample}/{species}/unfiltered.bam',
		barcode_whitelist='data/{sample}/{species}/barcodes.csv'
	output:
		'data/{sample}/{species}/umi_expression_matrix.txt'
	params:
		count_per_umi=config['EXTRACTION']['minimum-counts-per-UMI'],	
		memory=config['LOCAL']['memory'],
		temp_directory=config['LOCAL']['temp-directory']
	conda: '../envs/dropseq_tools.yaml'
	shell:
		"""export _JAVA_OPTIONS=-Djava.io.tmpdir={params.temp_directory} && DigitalExpression -m {params.memory}\
		-I {input.data}\
		-O {output}\
		-MIN_BC_READ_THRESHOLD {params.count_per_umi}\
		-CELL_BC_FILE {input.barcode_whitelist}"""

rule extract_reads_expression_species:
	input:
		data='data/{sample}/{species}/unfiltered.bam',
		barcode_whitelist='data/{sample}/{species}/barcodes.csv'
	params:
		memory=config['LOCAL']['memory'],
		temp_directory=config['LOCAL']['temp-directory']
	output:
		'data/{sample}/{species}/counts_expression_matrix.txt'
	conda: '../envs/dropseq_tools.yaml'
	shell:
		"""export _JAVA_OPTIONS=-Djava.io.tmpdir={params.temp_directory} && DigitalExpression -m {params.memory}\
		-I {input.data}\
		-O {output}\
		-CELL_BC_FILE {input.barcode_whitelist}\
		-OUTPUT_READS_INSTEAD true"""



rule SingleCellRnaSeqMetricsCollector_species:
	input:
		data='data/{sample}/{species}/unfiltered.bam',
		barcode_whitelist='data/{sample}/{species}/barcodes.csv',
		refFlat='{}.refFlat'.format(annotation_prefix),
		rRNA_intervals='{}.rRNA.intervals'.format(reference_prefix)
	params:
		cells=lambda wildcards: int(samples.loc[wildcards.sample,'expected_cells']),		
		memory=config['LOCAL']['memory'],
		temp_directory=config['LOCAL']['temp-directory']
	output:
		'logs/dropseq_tools/{sample}/{species}/rna_metrics.txt'
	conda: '../envs/dropseq_tools.yaml'
	shell:
		"""export _JAVA_OPTIONS=-Djava.io.tmpdir={params.temp_directory} && SingleCellRnaSeqMetricsCollector -m {params.memory}\
		INPUT={input.data}\
		OUTPUT={output}\
		ANNOTATIONS_FILE={input.refFlat}\
		CELL_BC_FILE={input.barcode_whitelist}\
		RIBOSOMAL_INTERVALS={input.rRNA_intervals}
		"""
rule plot_rna_metrics_species:
	input:
		rna_metrics='logs/dropseq_tools/{sample}/{species}/rna_metrics.txt',
		barcode='data/{sample}/{species}/barcodes.csv'
	conda: '../envs/plots.yaml'
	output:
		pdf='plots/rna_metrics/{sample}_{species}_rna_metrics.pdf'
	script:
		'../scripts/plot_rna_metrics.R'


rule merge_umi_species:
	input:
		expand('data/{sample}/{{species}}/umi_expression_matrix.txt', sample=samples.index)
	conda: '../envs/merge.yaml'
	output:
		'summary/Experiment_{species}_umi_expression_matrix.tsv'
	params:
		sample_names=lambda wildcards: samples.index
	script:
		"../scripts/merge_counts.R"

rule merge_counts_species:
	input:
		expand('data/{sample}/{{species}}/counts_expression_matrix.txt', sample=samples.index)
	conda: '../envs/merge.yaml'
	output:
		'summary/Experiment_{species}_counts_expression_matrix.tsv'
	params:
		sample_names=lambda wildcards: samples.index
	script:
		"../scripts/merge_counts.R"