### cnvOffSeq_1000_检测-pipeline

###### A3

###### 环境：savvycnv

###### 工具：XShell

###### cnvOffSeq 检测结果：/data/liyaowen/cnvOffSeq-master/CNV_calling/off_target_1_6_1000000_171050000/cnv/RD.txt

##### 一、预处理标准化流程

1.bam为输入，提取6号染色体

代码地址：/data/liyaowen/software/cnvOffSeq-master/run_extract_region_from_BAM.sh

结果地址：/data/liyaowen/software/cnvOffSeq-master/chr6-bam

```markup
#!/bin/bash

# 设置 BAM 文件所在目录和输出目录
BAM_DIR="/data/liyaowen/software/cnvOffSeq-master/1kgp_exome_bam"  # BAM 文件目录
OUTPUT_DIR="/data/liyaowen/software/cnvOffSeq-master/chr6-bam"      # 输出目录
CHROM="chr6"  # 需要提取的染色体

# 创建输出目录（如果不存在）
mkdir -p "$OUTPUT_DIR"

# 遍历 BAM 文件目录中的每个 BAM 文件
for BAM_FILE in "$BAM_DIR"/*.bam; do
    BASE_NAME=$(basename "$BAM_FILE" .bam)
    OUTPUT_BAM="$OUTPUT_DIR/${BASE_NAME}_${CHROM}.bam"

    echo "正在处理 $BAM_FILE，提取染色体 $CHROM..."
    
    # 调用提取脚本生成 BAM
    sh /data/liyaowen/software/cnvOffSeq-master/extract_region_from_BAM.sh "$BAM_FILE" "$OUTPUT_BAM" "$CHROM"

    # 生成对应的 BAI 索引
    samtools index "$OUTPUT_BAM"
    echo "已生成 BAM 和索引: $OUTPUT_BAM 和 ${OUTPUT_BAM}.bai"
done

echo "所有 BAM 文件提取完成，索引已生成。"

```

2.运行规范化管道

例如：读取深度：sh RD_pipeline_off_target.sh 6 60000 171050000

代码地址：/data/liyaowen/cnvOffSeq-master/RD_pipeline_off_target.sh

预处理脚本会将结果放入“/data/liyaowen/cnvOffSeq-master/pre_processing_results”中，并将预处理后的数据源复制到 ./CNV_calling/data 文件夹中。预处理完成后，该文件夹应包含标准化采样 RD 数据的 zip 文件

RD_pipeline_off_target.sh

```markup
#!/bin/sh

#RD_pipeline_capture script.

#First we need to define the working directory and the input directory.
#The input directory should only contain the BAM (and possibly the BAI index) files.
#The working directory is were all the intermediate and final results will be saved
#We assume each BAM file contains reads from one sample, for one chromosome.

chr=$1 #chromosome to perform analysis on
start=${2:-0} #start coordinate
stop=$3 #end coordinate
INPUT="/data/liyaowen/software/cnvOffSeq-master/chr6-bam" #input folder (containing the BAM files)

export OUTPUTDIR="/data/liyaowen/cnvOffSeq-master/pre_processing_results/RD_results"
export JARDIR="/data/liyaowen/cnvOffSeq-master/RD_normalization/"
export INPUT=${INPUT:="./bam/"}
export FINAL="/data/liyaowen/cnvOffSeq-master/CNV_calling/data/RD"

mkdir -p $OUTPUTDIR
mkdir -p $FINAL

#First, we process the BAM files by indexing, sorting and piling them up.

for f in $INPUT/*.bam
do
	echo "Processing file: $(basename $f) ..."	
	sh $JARDIR/process_one_off_target.sh $OUTPUTDIR $INPUT $f
done


#The next step is to sample (according to the windowSize parameter)
#and smoothe the read depth using the singular value decomposition.

window=100

echo "Smoothing Read Depth..."
sh $JARDIR/off_target_smoothe.sh $OUTPUTDIR $JARDIR $chr $start $stop $window


#The final step is to merge the sampled, smoothed files.

echo "Merging files..."
sh $JARDIR/merge_smoothed.sh $JARDIR $OUTPUTDIR $chr $start $stop $window

cp $OUTPUTDIR/Final_Merged/chr$chr"_"$start"_"$stop/*.zip $FINAL/$chr.zip

echo "Results copied to ./CNV_detection/data/RD folder"


```

##### 二、CNV检测

对标准化采样 RD 数据的 zip 文件进行CNV分析

代码地址：/data/liyaowen/cnvOffSeq-master/CNV_calling/run_cnvOffSeq.sh

```markup
#!/bin/sh

#the "mid" argument specifies which region the CNV analysis should be performed on.
#e.g. for one of the intergenic regions described in the manuscript this would be
#--mid 6:48.91mb:48.96mb

#the "baseDir" argument specifies where the input data is located

#the "include" argument specifies which data sources to include in the analysis
#by default RD is included

#the "plot" argument specifies whether to produce plots of
#the underlying data along with the segmentation
#to enable plotting set "plot" to 1
#if plot is set to 0, no plots will be created and the process will be faster

#the "numIt" argument defines the number of training iterations, which is set to
#5 here but should be increased if analyzing many samples simultaneously
cd /data/liyaowen/cnvOffSeq-master/CNV_calling

java -Xmx128g -cp ./cnvOffSeq.jar lc1.dp.appl.CNVHap --paramFile param.txt --mid 6:1000000:171050000 --baseDir ./data/ --index 1 --column 1 --numIt 5 --include RD --plot 0 --r_panel true --b_panel true --showScatter false --showHMM false  --expModelIntHotSpot 0.1:1:1e3 --collapseDupStates true > output_msg.txt 2>&1

```

