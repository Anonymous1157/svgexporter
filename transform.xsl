<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:svg="http://www.w3.org/2000/svg"
	xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape">
	<xsl:output method="xml" encoding="UTF-8" standalone="no" />
	<xsl:template name="identity" match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template name="layer-switcheroo" match="svg:g[@inkscape:groupmode='layer']">
		<xsl:choose>
		<xsl:when test="contains(@inkscape:label, 'Right ')">
			<xsl:variable name="potato"><xsl:value-of select="@inkscape:label"/></xsl:variable>
			<xsl:copy>
				<xsl:apply-templates select="@*"/>
			</xsl:copy>
			<xsl:copy-of select="document($cheeseburger)//svg:g[@inkscape:groupmode='layer'][@inkscape:label=$potato]"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:copy>
				<xsl:apply-templates select="node()|@*"/>
			</xsl:copy>
		</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="clipping-planes-switcheroo" match="svg:defs">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
		<xsl:copy-of select="document($cheeseburger)//svg:defs/*" />
	</xsl:template>
</xsl:stylesheet>